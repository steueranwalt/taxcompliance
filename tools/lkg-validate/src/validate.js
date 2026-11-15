"use strict";

const fs = require("fs");
const path = require("path");
const Ajv2020 = require("ajv/dist/2020");
const addFormats = require("ajv-formats");

const SCHEMA_PATH = path.resolve(__dirname, "../../../schema/lkg/graph.schema.json");

const COLLECTIONS = {
  NORM: "norms",
  NORM_VERSION: "norm_versions",
  SOURCE: "sources",
  RELATION: "relations",
  PROCEDURE: "procedures",
  PROCEDURE_STEP: "procedure_steps",
  EVENT: "events",
  STATE: "states",
  DECISION: "decisions",
  TRANSITION: "transitions",
  DEADLINE: "deadlines",
  LIMITATION: "limitations",
  OBLIGATION: "obligations",
  EVIDENCE: "evidence",
  FINDING: "findings",
  ACTION: "actions",
};

const RELATION_ENDS = {
  SOURCE_TO_NORM_VERSION: { from: "SOURCE", to: "NORM_VERSION" },
  SOURCE_TO_WIKI_NOTE: { from: "SOURCE", to: "SOURCE" },
  NORM_TO_NORM_VERSION: { from: "NORM", to: "NORM_VERSION" },
  NORM_VERSION_TO_PROCEDURE: { from: "NORM_VERSION", to: "PROCEDURE" },
  PROCEDURE_TO_PROCEDURE_STEP: { from: "PROCEDURE", to: "PROCEDURE_STEP" },
  EVENT_TO_DEADLINE: { from: "EVENT", to: "DEADLINE" },
  EVENT_TO_STATE: { from: "EVENT", to: "STATE" },
  EVENT_TO_LIMITATION: { from: "EVENT", to: "LIMITATION" },
  DECISION_TO_TRANSITION: { from: "DECISION", to: "TRANSITION" },
  TRANSITION_TO_STATE: { from: "TRANSITION", to: "STATE" },
  NORM_VERSION_TO_OBLIGATION: { from: "NORM_VERSION", to: "OBLIGATION" },
  OBLIGATION_TO_EVIDENCE: { from: "OBLIGATION", to: "EVIDENCE" },
  NORM_VERSION_TO_LIMITATION: { from: "NORM_VERSION", to: "LIMITATION" },
  NORM_VERSION_TO_DEADLINE: { from: "NORM_VERSION", to: "DEADLINE" },
  NORM_VERSION_TO_RULE: { from: "NORM_VERSION", to: "ACTION" },
  FINDING_TO_ACTION: { from: "FINDING", to: "ACTION" },
  FINDING_TO_OBLIGATION: { from: "FINDING", to: "OBLIGATION" },
};

function loadSchema() {
  return JSON.parse(fs.readFileSync(SCHEMA_PATH, "utf8"));
}

function createAjv() {
  const ajv = new Ajv2020({ allErrors: true, strict: false });
  addFormats(ajv);
  return ajv;
}

function indexGraph(graph) {
  const byType = {};
  const byId = new Map();
  for (const [type, key] of Object.entries(COLLECTIONS)) {
    const items = Array.isArray(graph[key]) ? graph[key] : [];
    byType[type] = items;
    for (const item of items) {
      if (!item || !item.id) continue;
      if (byId.has(item.id)) {
        byId.get(item.id).push({ type, item });
      } else {
        byId.set(item.id, [{ type, item }]);
      }
    }
  }
  return { byType, byId };
}

function dateOrder(from, to) {
  if (!from || !to) return true;
  return from <= to;
}

function rangesOverlap(aFrom, aTo, bFrom, bTo) {
  const aEnd = aTo || "9999-12-31";
  const bEnd = bTo || "9999-12-31";
  return aFrom <= bEnd && bFrom <= aEnd;
}

function semanticErrors(graph) {
  const errors = [];
  const { byType, byId } = indexGraph(graph);

  for (const [id, hits] of byId.entries()) {
    if (hits.length > 1) {
      errors.push({
        code: "DUPLICATE_ID",
        message: `ID ${id} kommt mehrfach vor: ${hits.map((h) => h.type).join(", ")}`,
        path: id,
      });
    }
  }

  function mustExist(type, id, path) {
    if (!id) return;
    const hits = byId.get(id);
    if (!hits) {
      errors.push({
        code: "DANGLING_REF",
        message: `Referenz ${id} (${type || "unbekannt"}) existiert nicht`,
        path,
      });
      return;
    }
    if (type && type !== "WIKI_NOTE" && type !== "RULE" && !hits.some((h) => h.type === type)) {
      errors.push({
        code: "DANGLING_REF",
        message: `Referenz ${id} ist nicht vom Typ ${type}`,
        path,
      });
    }
  }

  for (const version of byType.NORM_VERSION) {
    mustExist("NORM", version.norm_id, `norm_versions/${version.id}/norm_id`);
    if (!dateOrder(version.valid_from, version.valid_to)) {
      errors.push({
        code: "INVALID_VALIDITY",
        message: `NORM_VERSION ${version.id}: valid_from ${version.valid_from} liegt nach valid_to ${version.valid_to}`,
        path: `norm_versions/${version.id}`,
      });
    }
    for (const sid of version.source_ids || []) {
      mustExist("SOURCE", sid, `norm_versions/${version.id}/source_ids`);
    }
    for (const lid of version.limitation_ids || []) {
      mustExist("LIMITATION", lid, `norm_versions/${version.id}/limitation_ids`);
    }
    for (const pid of version.procedure_ids || []) {
      mustExist("PROCEDURE", pid, `norm_versions/${version.id}/procedure_ids`);
    }
    for (const did of version.deadline_ids || []) {
      mustExist("DEADLINE", did, `norm_versions/${version.id}/deadline_ids`);
    }
    for (const oid of version.obligation_ids || []) {
      mustExist("OBLIGATION", oid, `norm_versions/${version.id}/obligation_ids`);
    }
  }

  const versionsByNorm = new Map();
  for (const version of byType.NORM_VERSION) {
    const list = versionsByNorm.get(version.norm_id) || [];
    list.push(version);
    versionsByNorm.set(version.norm_id, list);
  }
  for (const [normId, versions] of versionsByNorm.entries()) {
    for (let i = 0; i < versions.length; i += 1) {
      for (let j = i + 1; j < versions.length; j += 1) {
        const a = versions[i];
        const b = versions[j];
        if (a.jurisdiction !== b.jurisdiction) continue;
        if (rangesOverlap(a.valid_from, a.valid_to, b.valid_from, b.valid_to)) {
          errors.push({
            code: "OVERLAPPING_VALIDITY",
            message: `NORM ${normId}: Fassungen ${a.id} und ${b.id} ueberschneiden sich`,
            path: `norm_versions/${a.id}`,
          });
        }
      }
    }
  }

  for (const rel of byType.RELATION) {
    if (!dateOrder(rel.valid_from, rel.valid_to)) {
      errors.push({
        code: "INVALID_VALIDITY",
        message: `RELATION ${rel.id}: valid_from liegt nach valid_to`,
        path: `relations/${rel.id}`,
      });
    }
    const expected = RELATION_ENDS[rel.type];
    if (expected) {
      if (rel.from_type !== expected.from || rel.to_type !== expected.to) {
        errors.push({
          code: "RELATION_TYPE_MISMATCH",
          message: `RELATION ${rel.id}: ${rel.type} erwartet ${expected.from} → ${expected.to}, hat ${rel.from_type} → ${rel.to_type}`,
          path: `relations/${rel.id}`,
        });
      }
    }
    mustExist(rel.from_type, rel.from_id, `relations/${rel.id}/from_id`);
    mustExist(rel.to_type, rel.to_id, `relations/${rel.id}/to_id`);
  }

  for (const limitation of byType.LIMITATION) {
    mustExist("NORM_VERSION", limitation.norm_version_id, `limitations/${limitation.id}/norm_version_id`);
    mustExist("EVENT", limitation.triggering_event_id, `limitations/${limitation.id}/triggering_event_id`);
  }

  for (const deadline of byType.DEADLINE) {
    mustExist("NORM_VERSION", deadline.norm_version_id, `deadlines/${deadline.id}/norm_version_id`);
    mustExist("EVENT", deadline.triggering_event_id, `deadlines/${deadline.id}/triggering_event_id`);
  }

  for (const obligation of byType.OBLIGATION) {
    mustExist("NORM_VERSION", obligation.norm_version_id, `obligations/${obligation.id}/norm_version_id`);
    mustExist("DEADLINE", obligation.deadline_id, `obligations/${obligation.id}/deadline_id`);
  }

  for (const step of byType.PROCEDURE_STEP) {
    mustExist("PROCEDURE", step.procedure_id, `procedure_steps/${step.id}/procedure_id`);
  }

  for (const transition of byType.TRANSITION) {
    mustExist("STATE", transition.from_state_id, `transitions/${transition.id}/from_state_id`);
    mustExist("STATE", transition.to_state_id, `transitions/${transition.id}/to_state_id`);
  }

  return errors;
}

function affectedByNormVersion(graph, versionId) {
  const { byType } = indexGraph(graph);
  const hits = [];
  for (const rel of byType.RELATION) {
    if (rel.from_id === versionId || rel.to_id === versionId) {
      hits.push({ via: "relation", id: rel.id, type: rel.type, from_id: rel.from_id, to_id: rel.to_id });
    }
  }
  const version = byType.NORM_VERSION.find((item) => item.id === versionId);
  if (version) {
    for (const key of ["procedure_ids", "deadline_ids", "limitation_ids", "obligation_ids", "rule_ids", "source_ids"]) {
      for (const id of version[key] || []) {
        hits.push({ via: key, id });
      }
    }
  }
  return hits;
}

function validateGraph(graph, options = {}) {
  const schema = options.schema || loadSchema();
  const ajv = options.ajv || createAjv();
  const validate = ajv.compile(schema);
  const schemaOk = validate(graph);
  const schemaErrors = schemaOk
    ? []
    : (validate.errors || []).map((err) => ({
        code: "SCHEMA",
        message: `${err.instancePath || "/"} ${err.message}`,
        path: err.instancePath || "/",
        details: err,
      }));
  const extra = schemaOk || options.alwaysSemantic ? semanticErrors(graph) : [];
  const errors = [...schemaErrors, ...extra];
  return {
    ok: errors.length === 0,
    errors,
  };
}

function validateFile(filePath) {
  const graph = JSON.parse(fs.readFileSync(filePath, "utf8"));
  return { graph, ...validateGraph(graph) };
}

module.exports = {
  SCHEMA_PATH,
  COLLECTIONS,
  loadSchema,
  validateGraph,
  validateFile,
  affectedByNormVersion,
  semanticErrors,
};
