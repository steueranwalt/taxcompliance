"""Azure Functions (Python v2 Programmiermodell), HTTP-anonym erreichbar.

Duenner Wrapper: die eigentliche Logik steht in `app/` (ohne Abhaengigkeit
von `azure.functions`), damit sie ohne Functions-Host/Azure-Pakete getestet
werden kann (siehe `backend/tests/`). Dieses Modul verdrahtet nur HTTP <->
`app.*`.

NICHT in dieser Session gegen eine echte Azure-Function-Host-Instanz oder
gegen echte Azure-/SharePoint-Ressourcen getestet (siehe README "Rahmen").
Lokal lauffaehig mit `func start`, sofern die Azure Functions Core Tools und
`requirements.txt` installiert sind (hier nicht Teil der VM-Grundausstattung).
"""

from __future__ import annotations

import json
import logging

import azure.functions as func

from app.access_control import AccessDenied, RateLimiter, verify_case_access
from app.conversation import ConversationEngine, ConversationError
from app.config import get_settings
from app.document_upload import UploadRejected
from app.llm_client import AzureOpenAIClient, MockLLMClient
from app.schema_catalog import SchemaCatalog
from app.session_store import SessionStore
from app.sharepoint_client import GraphSharePointClient, MockSharePointClient

logger = logging.getLogger("erfassungschat")

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

_settings = get_settings()
_sharepoint = (
    MockSharePointClient(_settings.mock_sharepoint_dir)
    if _settings.mock_sharepoint
    else GraphSharePointClient(
        site_hostname=_settings.graph_site_hostname,
        site_path=_settings.graph_site_path,
        managed_identity_client_id=_settings.managed_identity_client_id,
    )
)
_llm = (
    MockLLMClient()
    if _settings.mock_llm
    else AzureOpenAIClient(
        endpoint=_settings.aoai_endpoint,
        deployment=_settings.aoai_deployment,
        api_version=_settings.aoai_api_version,
        managed_identity_client_id=_settings.managed_identity_client_id,
    )
)
_sessions = SessionStore(ttl_minutes=_settings.session_ttl_minutes)
_schemas = SchemaCatalog(_settings.schema_output_dir)
_rate_limiter = RateLimiter(_settings)
_engine = ConversationEngine(
    sharepoint=_sharepoint, llm=_llm, settings=_settings, sessions=_sessions, schema_catalog=_schemas
)


def _json_response(payload: dict, status_code: int = 200) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps(payload, ensure_ascii=False), status_code=status_code, mimetype="application/json"
    )


def _client_key(req: func.HttpRequest) -> str:
    # X-Forwarded-For wird von Azure Front Door/Functions-Plattform gesetzt;
    # Fallback auf eine feste Kennung, falls lokal ohne Proxy getestet.
    return req.headers.get("X-Forwarded-For", "local").split(",")[0].strip()


@app.route(route="session/start", methods=["POST"])
def start_session(req: func.HttpRequest) -> func.HttpResponse:
    body = req.get_json()
    try:
        access = verify_case_access(
            case_id=body.get("case_id", ""),
            access_code=body.get("access_code", ""),
            client_key=_client_key(req),
            sharepoint=_sharepoint,
            settings=_settings,
            rate_limiter=_rate_limiter,
        )
    except AccessDenied as exc:
        logger.info("zugriff_verweigert grund=%s", exc.reason)
        return _json_response({"error": exc.reason, "message": exc.message}, status_code=403)

    session = _engine.start_session(access.case_id)
    return _json_response(
        {
            "session_id": session.session_id,
            "frage": _engine.question_text("legal_form_grundtyp"),
        }
    )


@app.route(route="session/{session_id}/message", methods=["POST"])
def post_message(req: func.HttpRequest) -> func.HttpResponse:
    session = _sessions.get(req.route_params["session_id"])
    if session is None:
        return _json_response({"error": "session_expired"}, status_code=410)
    body = req.get_json()
    result = _engine.submit_free_text_answer(
        session, body["list_name"], int(body.get("record_index", 0)), body["message"]
    )
    return _json_response(
        {"assistant_message": result.assistant_message, "unsure_fields": result.unsure_fields}
    )


@app.route(route="session/{session_id}/explain", methods=["GET"])
def explain(req: func.HttpRequest) -> func.HttpResponse:
    session = _sessions.get(req.route_params["session_id"])
    if session is None:
        return _json_response({"error": "session_expired"}, status_code=410)
    prompt_key = req.params.get("feld", "")
    return _json_response({"erklaerung": _engine.explain(prompt_key)})


@app.route(route="session/{session_id}/summary", methods=["GET"])
def summary(req: func.HttpRequest) -> func.HttpResponse:
    session = _sessions.get(req.route_params["session_id"])
    if session is None:
        return _json_response({"error": "session_expired"}, status_code=410)
    return _json_response(_engine.build_summary(session))


@app.route(route="session/{session_id}/confirm", methods=["POST"])
def confirm(req: func.HttpRequest) -> func.HttpResponse:
    session = _sessions.get(req.route_params["session_id"])
    if session is None:
        return _json_response({"error": "session_expired"}, status_code=410)
    _engine.confirm(session)
    return _json_response({"ok": True})


@app.route(route="session/{session_id}/submit", methods=["POST"])
def submit(req: func.HttpRequest) -> func.HttpResponse:
    session = _sessions.get(req.route_params["session_id"])
    if session is None:
        return _json_response({"error": "session_expired"}, status_code=410)
    try:
        outcome = _engine.submit(session)
    except ConversationError as exc:
        return _json_response({"error": exc.reason, "message": exc.message}, status_code=409)
    return _json_response(
        {
            "written_lists": outcome.written_lists,
            "deferred_sections": outcome.deferred_sections,
            "eingang_fehler_count": outcome.eingang_fehler_count,
        }
    )


@app.route(route="session/{session_id}/upload", methods=["POST"])
def upload(req: func.HttpRequest) -> func.HttpResponse:
    session = _sessions.get(req.route_params["session_id"])
    if session is None:
        return _json_response({"error": "session_expired"}, status_code=410)
    file = req.files.get("file")
    if file is None:
        return _json_response({"error": "missing_file"}, status_code=400)
    document_type = req.form.get("document_type", "Sonstiges")
    try:
        result = _engine.handle_upload(
            session,
            filename=file.filename,
            content_type=file.mimetype,
            data=file.read(),
            document_type=document_type,
        )
    except UploadRejected as exc:
        return _json_response({"error": exc.reason, "message": exc.message}, status_code=400)
    return _json_response({"file_link": result.file_link, "size_bytes": result.size_bytes})
