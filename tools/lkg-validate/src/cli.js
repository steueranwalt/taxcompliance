#!/usr/bin/env node
"use strict";

const path = require("path");
const { validateFile } = require("./validate");

const files = process.argv.slice(2);
if (files.length === 0) {
  process.stderr.write("Nutzung: node src/cli.js <graph.json> [...]\n");
  process.exit(2);
}

let failed = 0;
for (const file of files) {
  const resolved = path.resolve(file);
  const result = validateFile(resolved);
  if (result.ok) {
    process.stdout.write(`OK ${resolved}\n`);
  } else {
    failed += 1;
    process.stdout.write(`FEHLER ${resolved}\n`);
    for (const err of result.errors) {
      process.stdout.write(`  [${err.code}] ${err.message}\n`);
    }
  }
}

process.exit(failed === 0 ? 0 : 1);
