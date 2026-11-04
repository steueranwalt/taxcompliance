"use strict";

const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const { validateFile, validateGraph, affectedByNormVersion } = require("../src/validate");

const examples = path.resolve(__dirname, "../../../data/lkg/examples");

test("gueltiger §-171-Datensatz besteht Schema und Semantik", () => {
  const result = validateFile(path.join(examples, "valid-ao-171.json"));
  assert.equal(result.ok, true, JSON.stringify(result.errors, null, 2));
  assert.equal(result.graph.norm_versions[0].verification_status, "LEGAL_REVIEW_REQUIRED");
  assert.notEqual(result.graph.norm_versions[0].verification_status, "LEGAL_APPROVED");
});

test("fehlende Pflichtangaben werden erkannt", () => {
  const result = validateFile(path.join(examples, "invalid-missing-required.json"));
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((err) => err.code === "SCHEMA"));
});

test("ungueltige Referenzen werden erkannt", () => {
  const result = validateFile(path.join(examples, "invalid-dangling-ref.json"));
  assert.equal(result.ok, false);
  const codes = result.errors.map((err) => err.code);
  assert.ok(codes.includes("DANGLING_REF"), JSON.stringify(result.errors, null, 2));
});

test("widerspruechlicher Geltungszeitraum wird erkannt", () => {
  const result = validateFile(path.join(examples, "invalid-validity-range.json"));
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((err) => err.code === "INVALID_VALIDITY"),
    JSON.stringify(result.errors, null, 2)
  );
});

test("ueberlappende Normfassungen werden erkannt", () => {
  const result = validateFile(path.join(examples, "invalid-overlapping-versions.json"));
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((err) => err.code === "OVERLAPPING_VALIDITY"),
    JSON.stringify(result.errors, null, 2)
  );
});

test("Aenderungsfolgen einer Normversion sind erreichbar", () => {
  const result = validateFile(path.join(examples, "valid-ao-171.json"));
  const hits = affectedByNormVersion(result.graph, "DE-AO-0171-REG-2026-09-29");
  assert.ok(hits.some((hit) => hit.id === "LIM-DE-AO-0171-ABLAUFHEMMUNG" || hit.to_id === "LIM-DE-AO-0171-ABLAUFHEMMUNG"));
  assert.ok(hits.some((hit) => String(hit.id).includes("SRC-DE-FRISTENREGISTER") || String(hit.from_id || "").includes("SRC-DE-FRISTENREGISTER")));
});

test("leerer Graph ohne Hinweis ist ungueltig", () => {
  const result = validateGraph({});
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((err) => err.code === "SCHEMA"));
});
