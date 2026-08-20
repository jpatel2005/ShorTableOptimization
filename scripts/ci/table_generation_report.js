'use strict';

const childProcess = require('child_process');
const fs = require('fs');

const RESULTS_BRANCH = 'submission-results';
const RESULT_MARKER = '<!-- table-generation-submission-result -->';

function sourceRunId() {
  const runId = Number(process.env.SOURCE_RUN_ID || 0);
  if (!Number.isSafeInteger(runId) || runId <= 0) {
    throw new Error('Source workflow run ID is invalid.');
  }
  return runId;
}

async function sourceWorkflowRun(github, context) {
  const response = await github.rest.actions.getWorkflowRun({
    ...context.repo,
    run_id: sourceRunId(),
  });
  return response.data;
}

async function ensureResultsBranch(github, context) {
  const { owner, repo } = context.repo;
  try {
    const existing = await github.rest.git.getRef({
      owner,
      repo,
      ref: `heads/${RESULTS_BRANCH}`,
    });
    return existing.data.object.sha;
  } catch (error) {
    if (error.status !== 404) throw error;
  }

  const tree = await github.rest.git.createTree({ owner, repo, tree: [] });
  const commit = await github.rest.git.createCommit({
    owner,
    repo,
    message: 'chore(results): initialize generated archive',
    tree: tree.data.sha,
    parents: [],
  });
  try {
    await github.rest.git.createRef({
      owner,
      repo,
      ref: `refs/heads/${RESULTS_BRANCH}`,
      sha: commit.data.sha,
    });
    return commit.data.sha;
  } catch (error) {
    if (error.status !== 422) throw error;
    const existing = await github.rest.git.getRef({
      owner,
      repo,
      ref: `heads/${RESULTS_BRANCH}`,
    });
    return existing.data.object.sha;
  }
}

async function persistFiles(github, context, files, message) {
  const { owner, repo } = context.repo;
  const headSha = await ensureResultsBranch(github, context);
  const head = await github.rest.git.getCommit({
    owner,
    repo,
    commit_sha: headSha,
  });
  const entries = [];
  for (const [storedPath, localPath] of files) {
    const blob = await github.rest.git.createBlob({
      owner,
      repo,
      content: fs.readFileSync(localPath).toString('base64'),
      encoding: 'base64',
    });
    entries.push({
      path: storedPath,
      mode: '100644',
      type: 'blob',
      sha: blob.data.sha,
    });
  }

  const tree = await github.rest.git.createTree({
    owner,
    repo,
    base_tree: head.data.tree.sha,
    tree: entries,
  });
  if (tree.data.sha === head.data.tree.sha) return;

  const commit = await github.rest.git.createCommit({
    owner,
    repo,
    message,
    tree: tree.data.sha,
    parents: [headSha],
  });
  await github.rest.git.updateRef({
    owner,
    repo,
    ref: `heads/${RESULTS_BRANCH}`,
    sha: commit.data.sha,
  });
}

async function downloadExistingIndex(github, context) {
  const { owner, repo } = context.repo;
  try {
    const existing = await github.rest.repos.getContent({
      owner,
      repo,
      path: 'leaderboard/results.json',
      ref: RESULTS_BRANCH,
    });
    if (Array.isArray(existing.data) || existing.data.encoding !== 'base64') {
      throw new Error('Existing benchmark index is not a base64-encoded file.');
    }
    const localPath = 'artifacts/existing-benchmark-results.json';
    fs.writeFileSync(localPath, Buffer.from(existing.data.content, 'base64'));
    return localPath;
  } catch (error) {
    if (error.status === 404) return '';
    throw error;
  }
}

function buildBenchmarkIndex(existingPath) {
  const args = [
    'scripts/leaderboard.py',
    '--artifact',
    'artifacts/table-generation-submission-result.json',
    '--config',
    'leaderboard/config.json',
    '--out',
    'artifacts/benchmark-results.json',
    '--operations-out',
    'artifacts/benchmark-operations.json',
  ];
  if (existingPath) args.push('--existing', existingPath);
  childProcess.execFileSync('python3', args, { stdio: 'inherit' });
}

function repositoryFileUrl(context, storedPath) {
  const serverUrl = process.env.GITHUB_SERVER_URL || 'https://github.com';
  const encodedPath = storedPath.split('/').map(encodeURIComponent).join('/');
  const { owner, repo } = context.repo;
  return `${serverUrl}/${owner}/${repo}/blob/${RESULTS_BRANCH}/${encodedPath}`;
}

async function persistBenchmarkResults({ github, context, core }) {
  const resultPath = 'artifacts/table-generation-results.json';
  const reportPath = 'artifacts/table-generation-results.md';
  const sourcePath = 'artifacts/table-generation-submission-source.zip';
  const operationsPath = 'artifacts/benchmark-operations.json';
  const result = JSON.parse(fs.readFileSync(resultPath, 'utf8'));
  const workflowRun = await sourceWorkflowRun(github, context);
  if (workflowRun.conclusion !== 'success') {
    throw new Error('Benchmark results may only be persisted for successful workflows.');
  }

  const prNumber = String(
    result?.submission?.pr_number || workflowRun.pull_requests?.[0]?.number || ''
  ).trim();
  if (!/^\d+$/.test(prNumber)) {
    throw new Error('Benchmark result does not identify a pull request.');
  }

  const policyId = String(
    result?.submission?.head_sha || workflowRun.head_sha || ''
  ).toLowerCase().trim();
  if (!/^[0-9a-f]{40}$/.test(policyId)) {
    throw new Error('Benchmark result does not identify a policy commit.');
  }
  const storedDirectory = `results/policies/${policyId}`;
  const storedResultPath = `${storedDirectory}/results.json`;
  const storedReportPath = `${storedDirectory}/results.md`;
  const storedSourcePath = `${storedDirectory}/source.zip`;
  const storedOperationsPath = `${storedDirectory}/operations.json`;
  const storedIndexPath = 'leaderboard/results.json';
  const message = `chore(results): persist policy ${policyId.slice(0, 12)}`;

  const existingIndexPath = await downloadExistingIndex(github, context);
  buildBenchmarkIndex(existingIndexPath);
  await persistFiles(
    github,
    context,
    [
      [storedResultPath, resultPath],
      [storedReportPath, reportPath],
      [storedSourcePath, sourcePath],
      [storedOperationsPath, operationsPath],
      [storedIndexPath, 'artifacts/benchmark-results.json'],
    ],
    message
  );

  core.setOutput('results_json_url', repositoryFileUrl(context, storedResultPath));
  core.setOutput('results_report_url', repositoryFileUrl(context, storedReportPath));
  core.setOutput('source_archive_url', repositoryFileUrl(context, storedSourcePath));
  core.setOutput('operations_json_url', repositoryFileUrl(context, storedOperationsPath));
  core.setOutput('benchmark_index_url', repositoryFileUrl(context, storedIndexPath));
}

function readVerifierResult(core) {
  const resultPath = 'artifacts/table-generation-submission-result.json';
  if (!fs.existsSync(resultPath)) return null;
  try {
    return JSON.parse(fs.readFileSync(resultPath, 'utf8'));
  } catch (error) {
    core.warning(`Could not parse verifier result JSON: ${error.message}`);
    return null;
  }
}

function reportBody(result, workflowRun) {
  const benchmarkPath = 'artifacts/table-generation-results.md';
  const verifierSummaryPath = 'artifacts/table-generation-summary.md';
  const fallback = [
    RESULT_MARKER,
    '### Table generation submission',
    '',
    'Status: **FAILURE**',
    '',
    'The verifier did not produce a summary artifact. Check the workflow run.',
  ].join('\n');
  let body = fs.existsSync(benchmarkPath)
    ? fs.readFileSync(benchmarkPath, 'utf8')
    : fs.existsSync(verifierSummaryPath)
      ? fs.readFileSync(verifierSummaryPath, 'utf8')
      : fallback;

  if (
    result?.phase === 'preflight' &&
    result.status === 'success' &&
    workflowRun.conclusion !== 'success'
  ) {
    body = [
      RESULT_MARKER,
      '### Table generation submission',
      '',
      'Status: **FAILURE**',
      '',
      'Preflight checks passed, but full Lean verification did not complete.',
      'Check the workflow run.',
    ].join('\n');
  }
  return body;
}

async function upsertResultComment(github, context, prNumber, body) {
  const { owner, repo } = context.repo;
  const comments = await github.paginate(github.rest.issues.listComments, {
    owner,
    repo,
    issue_number: prNumber,
    per_page: 100,
  });
  const existing = comments.find(
    comment => comment.user.type === 'Bot' && comment.body.includes(RESULT_MARKER)
  );
  if (existing) {
    await github.rest.issues.updateComment({
      owner,
      repo,
      comment_id: existing.id,
      body,
    });
    return;
  }
  await github.rest.issues.createComment({ owner, repo, issue_number: prNumber, body });
}

async function reportPullRequestResult({ github, context, core }) {
  const workflowRun = await sourceWorkflowRun(github, context);
  const result = readVerifierResult(core);
  const serverUrl = process.env.GITHUB_SERVER_URL || 'https://github.com';
  const repositoryUrl = `${serverUrl}/${context.repo.owner}/${context.repo.repo}`;
  const workflowUrl = `${repositoryUrl}/actions/runs/${workflowRun.id}`;
  const links = [`[Workflow run](${workflowUrl})`];
  if (process.env.RESULTS_REPORT_URL) {
    links.push(`[Results report](${process.env.RESULTS_REPORT_URL})`);
  }
  if (process.env.RESULTS_JSON_URL) {
    links.push(`[Results JSON](${process.env.RESULTS_JSON_URL})`);
  }
  if (process.env.OPERATIONS_JSON_URL) {
    links.push(`[Operations JSON](${process.env.OPERATIONS_JSON_URL})`);
  }
  if (process.env.BENCHMARK_INDEX_URL) {
    links.push(`[Benchmark JSON](${process.env.BENCHMARK_INDEX_URL})`);
  }
  if (process.env.SOURCE_ARCHIVE_URL) {
    links.push(`[Source archive](${process.env.SOURCE_ARCHIVE_URL})`);
  }
  let body = reportBody(result, workflowRun).trimEnd();
  const verifiedSuccessfully =
    workflowRun.conclusion === 'success' &&
    result?.phase === 'full' &&
    result.status === 'success';
  if (verifiedSuccessfully && process.env.PERSIST_OUTCOME !== 'success') {
    body += '\n\nBenchmark results could not be archived; the PR has been left open.';
  }
  body = `${body}\n\n${links.join(' · ')}\n`;

  const prNumber = Number(
    result?.metadata?.pr_number || workflowRun.pull_requests?.[0]?.number || 0
  );
  if (!Number.isInteger(prNumber) || prNumber <= 0) {
    core.warning('Could not identify the pull request; no comment was posted.');
    return;
  }

  await upsertResultComment(github, context, prNumber, body);
  if (!result) {
    core.info('No result JSON found; leaving PR open.');
    return;
  }
  if (workflowRun.conclusion !== 'success') {
    core.info(
      `Verification workflow conclusion is ${workflowRun.conclusion}; leaving PR open.`
    );
    return;
  }
  if (result.phase !== 'full') {
    core.info(`Verifier phase is ${result.phase}; leaving PR open.`);
    return;
  }
  if (result.status !== 'success') {
    core.info(`Submission status is ${result.status}; leaving PR open.`);
    return;
  }
  if (process.env.PERSIST_OUTCOME !== 'success') {
    core.info('Benchmark persistence did not succeed; leaving PR open.');
    return;
  }

  await github.rest.pulls.update({
    ...context.repo,
    pull_number: prNumber,
    state: 'closed',
  });
}

module.exports = { persistBenchmarkResults, reportPullRequestResult };
