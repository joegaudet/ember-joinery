// The release workflows' promises, checked: nothing publishes on a push or a merge, only a
// pushed v* tag (release.yml) or a confirmed manual dispatch (bootstrap-publish.yml) does, and
// the tag check refuses a tag that doesn't match the packages.
//
// The root has no YAML parser, so these read the workflow files as text, one top-level key or
// job at a time, with comments stripped.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import {
  existsSync,
  mkdtempSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const WORKFLOWS = join(dirname(fileURLToPath(import.meta.url)), '..', '.github', 'workflows')
const read = file => readFileSync(join(WORKFLOWS, file), 'utf8')

/** The text without YAML comments (a `#` at the start of a line or after whitespace). */
const uncommented = source =>
  source
    .split('\n')
    .map(line => line.replace(/(^|\s)#.*$/, ''))
    .filter(line => line.trim())
    .join('\n')

const depth = line => line.match(/^ */)[0].length

/** The lines of `key:` at the given indent, up to the next line that isn't nested under it. */
function block(source, key, indent = '') {
  const lines = uncommented(source).split('\n')
  const start = lines.findIndex(line => new RegExp(`^${indent}${key}:( |$)`).test(line))
  assert.notEqual(start, -1, `\`${indent}${key}:\` is in the workflow`)
  const end = lines.findIndex((line, i) => i > start && depth(line) <= indent.length)
  return lines.slice(start, end === -1 ? undefined : end).join('\n')
}

/** The names directly under a block's key (one indent level deeper). */
const childKeys = (text, indent) =>
  text
    .split('\n')
    .slice(1)
    .map(line => line.match(new RegExp(`^${indent}([\\w-]+):`))?.[1])
    .filter(Boolean)

const job = (source, name) => block(source, name, '  ')

// bootstrap-publish.yml is one-shot: it is deleted once every package has been published, and
// restored from history when a new package needs its first publish.
const bootstrap = {
  skip: !existsSync(join(WORKFLOWS, 'bootstrap-publish.yml')) && 'bootstrap-publish.yml is deleted',
}

// The commands that put a package on the registry.
const PUBLISHES =
  /\bpnpm (run )?release\b|\bnpm publish\b|\bchangeset publish\b|scripts\/publish\.mjs/

test('release.yml runs on pushes to main and v* tags, nothing else', () => {
  const on = block(read('release.yml'), 'on')
  assert.deepEqual(childKeys(on, '  '), ['push'])
  assert.match(on, /branches: \[main\]/)
  assert.match(on, /tags: \['v\*'\]/)
})

test('release.yml publishes only from a v* tag', () => {
  const source = read('release.yml')
  assert.deepEqual(childKeys(block(source, 'jobs'), '  '), ['version', 'publish'])

  const publish = job(source, 'publish')
  assert.match(publish, /^ {4}if: startsWith\(github\.ref, 'refs\/tags\/v'\)$/m)
  assert.match(publish, PUBLISHES)
  // OIDC trusted publishing: no long-lived token in the job.
  assert.match(publish, /id-token: write/)
  assert.doesNotMatch(publish, /NPM_TOKEN|NODE_AUTH_TOKEN/)
  // The tag is checked against main and the packages before anything is built.
  assert.ok(publish.indexOf('merge-base --is-ancestor') < publish.indexOf('pnpm release'))
})

test("release.yml's version job only opens the version PR, and needs the release App", () => {
  const version = job(read('release.yml'), 'version')
  assert.match(
    version,
    /^ {4}if: github\.ref == 'refs\/heads\/main' && vars\.RELEASE_APP_CLIENT_ID != ''$/m,
  )
  assert.match(version, /client-id: \$\{\{ vars\.RELEASE_APP_CLIENT_ID \}\}/)
  assert.match(version, /private-key: \$\{\{ secrets\.RELEASE_APP_PRIVATE_KEY \}\}/)
  assert.match(version, /github-token: \$\{\{ steps\.app-token\.outputs\.token \}\}/)
  assert.doesNotMatch(version, PUBLISHES)
  // changesets/action publishes only when given a publish script.
  assert.doesNotMatch(version, /publish/)
})

test(
  'bootstrap-publish.yml runs only when dispatched by hand, and asks for confirmation',
  bootstrap,
  () => {
    const source = read('bootstrap-publish.yml')
    assert.deepEqual(childKeys(block(source, 'on'), '  '), ['workflow_dispatch'])

    const run = job(source, 'bootstrap')
    assert.match(run, /inputs\.confirm == 'publish'/)
    assert.match(run, /github\.ref == 'refs\/heads\/main'/)
    assert.match(run, /startsWith\(github\.ref, 'refs\/heads\/changeset-release\/'\)/)
    assert.match(run, /^ {4}environment: npm-bootstrap$/m)
    assert.match(run, /NODE_AUTH_TOKEN: \$\{\{ secrets\.NPM_TOKEN \}\}/)
  },
)

test("bootstrap-publish.yml's instructions name this repository and scope", bootstrap, () => {
  const source = read('bootstrap-publish.yml')
  assert.match(source, /joegaudet\/ember-joinery/)
  assert.match(source, /@ember-joinery\//)
  assert.doesNotMatch(source, /joegaudet\/ember-formwright|@ember-formwright\//)
})

test('no other workflow publishes', () => {
  const others = readdirSync(WORKFLOWS).filter(
    file => /\.ya?ml$/.test(file) && !['release.yml', 'bootstrap-publish.yml'].includes(file),
  )
  for (const file of others) {
    assert.doesNotMatch(uncommented(read(file)), PUBLISHES, `${file} must not publish`)
  }
})

// release.yml's tag check, run as the workflow runs it, in a throwaway workspace.
function checkTag(version, packages) {
  const lines = read('release.yml').split('\n')
  const start = lines.findIndex(line => line.includes("<<'JS'"))
  const end = lines.findIndex((line, i) => i > start && line.trim() === 'JS')
  assert.ok(start !== -1 && end !== -1, "release.yml's tag check is a <<'JS' heredoc")
  const body = lines.slice(start + 1, end)
  const indent = Math.min(...body.filter(l => l.trim()).map(l => l.match(/^ */)[0].length))

  const root = mkdtempSync(join(tmpdir(), 'release-tag-'))
  try {
    writeFileSync(join(root, 'check.cjs'), body.map(l => l.slice(indent)).join('\n'))
    for (const [dir, manifest] of Object.entries(packages)) {
      mkdirSync(join(root, 'packages', dir), { recursive: true })
      writeFileSync(join(root, 'packages', dir, 'package.json'), JSON.stringify(manifest))
    }
    // A folder without a package.json (a stray build directory) is not a package.
    mkdirSync(join(root, 'packages', 'stray'), { recursive: true })
    const run = spawnSync(process.execPath, ['check.cjs', version], { cwd: root, encoding: 'utf8' })
    return { status: run.status, output: run.stdout + run.stderr }
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
}

test("the tag check passes when every public package has the tag's version", () => {
  const { status } = checkTag('1.0.0', {
    ember: { name: '@ember-joinery/ember', version: '1.0.0' },
    primitives: { name: '@ember-joinery/primitives', version: '1.0.0' },
    // Private packages are never published, so their version doesn't matter.
    parity: { name: 'parity', version: '0.0.0', private: true },
  })
  assert.equal(status, 0)
})

test('the tag check names every public package whose version differs', () => {
  const { status, output } = checkTag('1.1.0', {
    ember: { name: '@ember-joinery/ember', version: '1.1.0' },
    primitives: { name: '@ember-joinery/primitives', version: '1.0.0' },
    chart: { name: '@ember-joinery/chart', version: '1.0.0' },
  })
  assert.equal(status, 1)
  assert.match(output, /::error::@ember-joinery\/primitives is 1\.0\.0, tag is v1\.1\.0/)
  assert.match(output, /::error::@ember-joinery\/chart is 1\.0\.0, tag is v1\.1\.0/)
  assert.doesNotMatch(output, /@ember-joinery\/ember is/)
})

test('the tag check compares prerelease versions exactly', () => {
  const packages = { ember: { name: '@ember-joinery/ember', version: '1.1.0-next.0' } }
  assert.equal(checkTag('1.1.0-next.0', packages).status, 0)
  assert.equal(checkTag('1.1.0', packages).status, 1)
})
