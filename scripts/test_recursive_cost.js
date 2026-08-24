#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const childProcess = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const RecursiveCost = require("../leaderboard/site/recursive-cost.js");

const binaryCandidate = {
  policyId: "test-binary",
  k: 2,
  operations: [
    ["phaseProduct", 0],
    ["phaseProduct", 1],
  ],
};

const transitionCandidate = {
  policyId: "test-transitions",
  k: 3,
  operations: [
    ["shiftL", 0, 3],
    ["shiftR", 1, 2],
    ["negate", 2],
    ["addScaled", 0, 2, 1, 4],
    ["addScaled", 2, 1, -1, 1],
    ["phaseProduct", 0],
  ],
};

let leanModulesBuilt = false;

function ensureLeanModulesBuilt(repository) {
  if (leanModulesBuilt) return;
  const result = childProcess.spawnSync(
    "lake",
    ["build", "TableGeneration.RecursiveCost.Correctness"],
    { cwd: repository, encoding: "utf8", maxBuffer: 8 * 1024 * 1024 },
  );
  if (result.status !== 0) {
    throw new Error(`Lean build failed:\n${result.stdout}\n${result.stderr}`);
  }
  leanModulesBuilt = true;
}

function testWidthModel() {
  assert.equal(RecursiveCost.phaseLimbWidth(10, 8, 3), 2);
  assert.deepEqual(RecursiveCost.initWidthState(10, 8, 3), {
    xw: [2, 2, 6],
    zw: [2, 2, 4],
  });

  const initial = RecursiveCost.initWidthState(8, 8, 2);
  const shifted = RecursiveCost.updateWidthState(initial, ["shiftL", 0, 1], 2);
  assert.deepEqual(shifted, { xw: [5, 4], zw: [5, 4] });
  const negated = RecursiveCost.updateWidthState(shifted, ["negate", 1], 2);
  assert.deepEqual(negated, { xw: [5, 5], zw: [5, 5] });
  const added = RecursiveCost.updateWidthState(
    negated,
    ["addScaled", 0, 1, -1, 2],
    2,
  );
  assert.deepEqual(added, { xw: [8, 5], zw: [8, 5] });
  assert.equal(
    RecursiveCost.nextSignedWidth(8, 8, 2, [
      ["shiftL", 0, 1],
      ["negate", 1],
      ["addScaled", 0, 1, -1, 2],
      ["phaseProduct", 0],
    ]),
    9,
  );
}

function testGateModel() {
  assert.equal(RecursiveCost.rippleAdderGateBound(7), 65n);
  assert.equal(RecursiveCost.negateGateBound(7), 72n);
  assert.equal(RecursiveCost.directSignedPhaseProductGateCount(7, 9), 63n);

  const analysis = RecursiveCost.analyzeProgram(8, 8, {
    policyId: "arithmetic-test",
    k: 2,
    operations: [
      ["shiftL", 0, 1],
      ["negate", 1],
      ["addScaled", 0, 1, 1, 2],
      ["phaseProduct", 0],
    ],
  });
  assert.deepEqual(analysis, {
    childWidth: 9,
    arithmeticGateCount: 350n,
    arithmeticOperationCount: 3,
    recursiveCallCount: 1,
  });
}

function testPlanner() {
  const width8 = RecursiveCost.bestPlan([binaryCandidate], 8);
  assert.equal(width8.gateCount, 50n);
  assert.equal(width8.recursionHeight, 1);
  assert.equal(width8.totalRecursiveCallCount, 2n);
  assert.equal(width8.choice.k, 2);
  assert.equal(width8.choice.childWidth, 5);

  const width16 = RecursiveCost.bestPlan([binaryCandidate], 16);
  assert.equal(width16.gateCount, 128n);
  assert.equal(width16.recursionHeight, 3);
  assert.equal(width16.totalRecursiveCallCount, 14n);
  assert.deepEqual(RecursiveCost.compactPlan(width16), {
    model_version: RecursiveCost.modelVersion,
    objective: RecursiveCost.objective,
    width: 16,
    gate_count: "128",
    recursion_height: 3,
    recursive_call_count: "14",
    arithmetic_operation_count: "0",
    steps: [
      {
        type: "recursive",
        level: 0,
        input_width: 16,
        instances: "1",
        policy_id: "test-binary",
        k: 2,
        child_width: 9,
        recursive_products_per_node: 2,
        local_gate_count_per_node: "0",
        expanded_local_gate_count: "0",
        local_arithmetic_operations_per_node: 0,
        expanded_arithmetic_operations: "0",
      },
      {
        type: "recursive",
        level: 1,
        input_width: 9,
        instances: "2",
        policy_id: "test-binary",
        k: 2,
        child_width: 6,
        recursive_products_per_node: 2,
        local_gate_count_per_node: "0",
        expanded_local_gate_count: "0",
        local_arithmetic_operations_per_node: 0,
        expanded_arithmetic_operations: "0",
      },
      {
        type: "recursive",
        level: 2,
        input_width: 6,
        instances: "4",
        policy_id: "test-binary",
        k: 2,
        child_width: 4,
        recursive_products_per_node: 2,
        local_gate_count_per_node: "0",
        expanded_local_gate_count: "0",
        local_arithmetic_operations_per_node: 0,
        expanded_arithmetic_operations: "0",
      },
      {
        type: "direct",
        level: 3,
        input_width: 4,
        instances: "8",
        gate_count_per_node: "16",
        expanded_gate_count: "128",
      },
    ],
  });
  const contributions = RecursiveCost.planLevels(width16).reduce(
    (total, level) => total + (level.type === "direct"
      ? level.expandedGateCount
      : level.expandedLocalGateCount),
    0n,
  );
  assert.equal(contributions, width16.gateCount);
}

async function testArchivedCatalog() {
  const policyA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  const policyB = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
  const data = {
    policies: [
      {
        policy_id: policyB,
        operations_path: "b/operations.json",
        results: [
          {
            mode: "PhaseProduct",
            k: 3,
            total_operation_count: 2,
            phase_product_count: 1,
            arithmetic_operation_count: 1,
          },
          { mode: "PhaseTripleProduct", k: 2 },
        ],
      },
      {
        policy_id: policyA,
        operations_path: "a/operations.json",
        results: [
          {
            mode: "PhaseProduct",
            k: 3,
            total_operation_count: 1,
            phase_product_count: 1,
            arithmetic_operation_count: 0,
          },
          {
            mode: "PhaseProduct",
            k: 2,
            total_operation_count: 2,
            phase_product_count: 1,
            arithmetic_operation_count: 1,
          },
        ],
      },
    ],
  };
  const operationData = {
    "a/operations.json": {
      schema_version: 1,
      policy_id: policyA,
      targets: [
        { mode: "PhaseProduct", k: 2, operations: [["negate", 0], ["phaseProduct", 0]] },
        { mode: "PhaseProduct", k: 3, operations: [["phaseProduct", 1]] },
      ],
    },
    "b/operations.json": {
      schema_version: 1,
      policy_id: policyB,
      targets: [
        { mode: "PhaseProduct", k: 3, operations: [["shiftL", 0, 1], ["phaseProduct", 0]] },
      ],
    },
  };
  const loads = [];
  const candidates = await RecursiveCost.archivedPhaseProductCandidates(data, path_ => {
    loads.push(path_);
    return operationData[path_];
  });
  assert.deepEqual(candidates.map(candidate => [candidate.k, candidate.policyId]), [
    [2, policyA],
    [3, policyA],
    [3, policyB],
  ]);
  assert.deepEqual(loads.sort(), ["a/operations.json", "b/operations.json"]);
}

async function testPublishedArchive() {
  const configuredRoot = process.env.TABLE_GEN_RESULTS_ROOT;
  if (!configuredRoot) return;
  const resultsRoot = path.resolve(process.cwd(), configuredRoot);
  const data = JSON.parse(
    fs.readFileSync(path.join(resultsRoot, "leaderboard/results.json"), "utf8"),
  );
  const expectedCount = RecursiveCost.phaseProductResultDescriptors(data).length;
  const candidates = await RecursiveCost.archivedPhaseProductCandidates(data, operationsPath =>
    JSON.parse(fs.readFileSync(path.join(resultsRoot, operationsPath), "utf8")));
  assert(expectedCount > 0);
  assert.equal(candidates.length, expectedCount);
  const plans = RecursiveCost.bestPlans(candidates, [2048, 4096]);
  assert.deepEqual(plans.map(plan => plan.width), [2048, 4096]);
  assert(plans.every(plan => plan.gateCount > 0n));
}

function deterministicWidths() {
  const widths = Array.from({ length: 257 }, (_, index) => index);
  widths.push(511, 512, 513, 2048, 4096);
  let state = 0x5eed1234;
  for (let index = 0; index < 64; index += 1) {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    widths.push(1 + (state % 4096));
  }
  return [...new Set(widths)];
}

function runLeanOracle(arguments_) {
  const repository = path.resolve(__dirname, "..");
  ensureLeanModulesBuilt(repository);
  const oracle = path.join(repository, "scripts/tests/RecursiveCostOracle.lean");
  const result = childProcess.spawnSync(
    "lake",
    ["env", "lean", "--run", oracle, ...arguments_],
    { cwd: repository, encoding: "utf8", maxBuffer: 8 * 1024 * 1024 },
  );
  if (result.status !== 0) {
    throw new Error(`Lean oracle failed:\n${result.stdout}\n${result.stderr}`);
  }
  return result.stdout.trim().split("\n").filter(Boolean);
}

function leanPlans(widths, mode = null) {
  const arguments_ = mode === null
    ? widths.map(String)
    : [mode, ...widths.map(String)];
  return runLeanOracle(arguments_).map(line => {
    const [width, gates, height, calls, arithmetic, choice] = line.split("\t");
    return { width, gates, height, calls, arithmetic, choice };
  });
}

function bestKnownCatalog() {
  return runLeanOracle(["--catalog"]).map(line => {
    const [marker, policyId, rawK, rawOperations] = line.split("\t");
    assert.equal(marker, "candidate");
    const operations = rawOperations === "" ? [] : rawOperations.split(";").map(encoded => {
      const [name, ...values] = encoded.split(",");
      return [name, ...values.map(Number)];
    });
    return { policyId, k: Number(rawK), operations };
  });
}

function testBalancedReferenceAgreement() {
  const widths = Array.from({ length: 65 }, (_, index) => index);
  const lines = runLeanOracle(["--reference", ...widths.map(String)]);
  assert.equal(lines.length, widths.length * 2);
  for (const line of lines) {
    const [marker, policyId, width, fast, reference] = line.split("\t");
    assert.equal(marker, "reference");
    assert(["test-binary", "test-transitions"].includes(policyId));
    assert(Number.isSafeInteger(Number(width)));
    assert.equal(fast, reference);
  }
}

function testDenseSparseAgreement() {
  const widths = [
    ...Array.from({ length: 33 }, (_, index) => index),
    63, 64, 65, 127, 128,
  ];
  for (const candidates of [
    [binaryCandidate],
    [transitionCandidate],
    [binaryCandidate, transitionCandidate],
  ]) {
    const dense = RecursiveCost.buildPlanTable(candidates, Math.max(...widths));
    const memoized = RecursiveCost.bestPlans(candidates, widths);
    memoized.forEach((plan, index) => assert.deepEqual(plan, dense[widths[index]]));
  }
  assert.deepEqual(
    runLeanOracle(["--dense-sparse", ...widths.map(String)]),
    ["dense/sparse agreement passed"],
  );
}

function testLeanDifferential() {
  const widths = deterministicWidths();
  const lean = leanPlans(widths);
  assert.equal(lean.length, widths.length);
  lean.forEach((expected, index) => {
    const width = widths[index];
    const actual = RecursiveCost.bestPlan([binaryCandidate], width);
    const choice = actual.choice === null
      ? "base"
      : `${actual.choice.k}:${actual.choice.childWidth}:${actual.choice.policyId}`;
    assert.deepEqual(expected, {
      width: String(width),
      gates: String(actual.gateCount),
      height: String(actual.recursionHeight),
      calls: String(actual.totalRecursiveCallCount),
      arithmetic: String(actual.totalArithmeticOperationCount),
      choice,
    });
  });
}

function testBestKnownDifferential() {
  const candidates = bestKnownCatalog();
  assert.deepEqual(candidates.map(candidate => candidate.k), [
    2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  ]);
  const widths = [
    ...Array.from({ length: 65 }, (_, index) => index),
    127, 128, 129, 2048, 4096,
  ];
  const lean = leanPlans(widths, "--best-known");
  const plans = RecursiveCost.bestPlans(candidates, widths);
  const dense = RecursiveCost.buildPlanTable(candidates, 129);
  lean.forEach((expected, index) => {
    const width = widths[index];
    const actual = plans[index];
    const choice = actual.choice === null
      ? "base"
      : `${actual.choice.k}:${actual.choice.childWidth}:${actual.choice.policyId}`;
    assert.deepEqual(expected, {
      width: String(width),
      gates: String(actual.gateCount),
      height: String(actual.recursionHeight),
      calls: String(actual.totalRecursiveCallCount),
      arithmetic: String(actual.totalArithmeticOperationCount),
      choice,
    });
    if (width <= 129) assert.deepEqual(actual, dense[width]);
  });

}

async function main() {
  testWidthModel();
  testGateModel();
  testPlanner();
  await testArchivedCatalog();
  await testPublishedArchive();
  testBalancedReferenceAgreement();
  testDenseSparseAgreement();
  testLeanDifferential();
  testBestKnownDifferential();
  console.log("recursive cost tests passed");
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
