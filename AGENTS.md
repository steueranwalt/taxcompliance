# AGENTS.md

## Cursor Cloud specific instructions

### Nature of this repository

This repo is a German/Swiss tax-law documentation tree
("Tax Compliance – Wissensbasis"). The primary content is Markdown
(`README.md`, `INDEX.md`, per-topic `README.md`s, `_migration/*.md`)
plus `.gitkeep` placeholders.

Phase 1 adds a small machine-readable layer that must not replace the
knowledge tree:

- `schema/lkg/graph.schema.json` — Legal Knowledge Graph
- `data/lkg/examples/` — fixtures (no mandate/personal data)
- `tools/lkg-validate/` — local Node validator (`npm test`)

That tool folder is the only committed `package.json`. Do not turn the repo
into an application. Do not invent legal sources. `LEGAL_APPROVED` is never
set by an agent.

### Dependencies / update script

There are **no root project dependencies**. The update script is
intentionally a no-op. The only install is optional and local:

```
cd tools/lkg-validate && npm install && npm test
```

Node.js and Python are preinstalled on the VM if you need ad-hoc tooling.

### Linting the docs

Markdown lint can be run ad hoc (no config is committed, so this uses default
rules and will report pre-existing style findings — that is expected):

```
npx --yes markdownlint-cli2 "**/*.md" "#node_modules"
```

Do not "fix" existing lint findings unless explicitly asked; the authors have
not adopted a linter config.

### Previewing the rendered knowledge base ("running the app")

The closest thing to running this project is previewing the rendered Markdown
in a browser. A minimal, self-contained preview server (using `markdown-it`)
can be created in a temp dir outside the repo — do **not** commit it. Example:

```
mkdir -p /tmp/mdpreview && cd /tmp/mdpreview
npm init -y >/dev/null && npm install markdown-it
# write a small http server that renders /workspace/**/*.md with markdown-it
node server.js /workspace 8099   # then open http://localhost:8099
```

GitHub itself renders these files directly, so viewing on GitHub is also a
valid preview path.
