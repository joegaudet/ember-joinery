import { test } from 'node:test'
import assert from 'node:assert/strict'
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { buildRegistry } from '../packages/cli/lib/build-registry.mjs'
import { run, unifiedDiff } from '../packages/cli/lib/cli.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const registryDir = mkdtempSync(join(tmpdir(), 'cli-registry-'))
buildRegistry({ emberDir: join(root, 'packages/ember'), outDir: registryDir, version: '1.2.0' })
const source = file => readFileSync(join(registryDir, 'files', file), 'utf8')

/** A throwaway app: a package.json with these dependencies, and a pnpm lockfile. */
function app(dependencies = {}) {
  const cwd = mkdtempSync(join(tmpdir(), 'cli-app-'))
  writeFileSync(join(cwd, 'package.json'), JSON.stringify({ name: 'my-app', dependencies }))
  writeFileSync(join(cwd, 'pnpm-lock.yaml'), '')
  return cwd
}

/** Runs the CLI in `cwd`, collecting what it prints and what it installs. */
async function cli(cwd, args, { isTTY = false, answer = false } = {}) {
  const out = []
  const installs = []
  const questions = []
  const code = await run(args, {
    cwd,
    registryDir,
    isTTY,
    stdout: text => out.push(text),
    stderr: text => out.push(text),
    confirm: async question => (questions.push(question), answer),
    install: (pm, specs, dir) => installs.push({ pm, specs, dir }),
  })
  return { code, output: out.join(''), installs, questions }
}

const target = (cwd, file) => join(cwd, 'app/joinery', file)

test('add copies the component, the components it imports and its -private files', async () => {
  const cwd = app()
  const { code } = await cli(cwd, ['add', 'dialog'])
  assert.equal(code, 0)
  for (const file of ['components/dialog.gts', 'components/button.gts', 'components/icon.gts']) {
    assert.equal(readFileSync(target(cwd, file), 'utf8'), source(file), file)
  }
})

test('add installs the npm packages the copies need with the lockfile’s package manager', async () => {
  const cwd = app()
  const { installs } = await cli(cwd, ['add', 'dialog'])
  assert.deepEqual(installs, [
    { pm: 'pnpm', specs: ['@ember-joinery/primitives@^1.2.0', 'lucide@^0.474.0'], dir: cwd },
  ])
})

test('add installs nothing the app already has, and leaves workspace and file specs alone', async () => {
  const cwd = app({ '@ember-joinery/primitives': 'workspace:*', lucide: '^0.400.0' })
  const { installs } = await cli(cwd, ['add', 'dialog'])
  assert.deepEqual(installs, [])
})

test('an update bumps @ember-joinery/primitives when the app’s range is older', async () => {
  const older = app({ '@ember-joinery/primitives': '^1.0.0', lucide: '^0.474.0' })
  assert.deepEqual((await cli(older, ['add', 'button'])).installs[0].specs, [
    '@ember-joinery/primitives@^1.2.0',
  ])
  const newer = app({ '@ember-joinery/primitives': '^1.3.0', lucide: '^0.474.0' })
  assert.deepEqual((await cli(newer, ['add', 'button'])).installs, [])
})

test('the first add writes joinery.json, and later runs read its path', async () => {
  const cwd = app()
  await cli(cwd, ['add', 'button', '--path', 'app/ui'])
  assert.deepEqual(JSON.parse(readFileSync(join(cwd, 'joinery.json'), 'utf8')).path, 'app/ui')
  assert.ok(existsSync(join(cwd, 'app/ui/components/button.gts')))
  await cli(cwd, ['add', 'badge'])
  assert.ok(existsSync(join(cwd, 'app/ui/components/badge.gts')))
})

test('a file identical to this version’s is left alone, and not reported', async () => {
  const cwd = app()
  await cli(cwd, ['add', 'button'])
  const { output, questions } = await cli(cwd, ['add', 'button'], { isTTY: true })
  assert.deepEqual(questions, [])
  assert.doesNotMatch(output, /skipped/i)
})

test('a changed file prompts in a terminal, and is overwritten on yes', async () => {
  const cwd = app()
  await cli(cwd, ['add', 'button'])
  writeFileSync(target(cwd, 'components/button.gts'), 'mine\n')
  const { questions } = await cli(cwd, ['add', 'button'], { isTTY: true, answer: true })
  assert.equal(questions.length, 1)
  assert.match(questions[0], /button\.gts already exists/)
  assert.equal(
    readFileSync(target(cwd, 'components/button.gts'), 'utf8'),
    source('components/button.gts'),
  )
})

test('a changed file is kept on no, under --yes, and without a terminal, and the skip is reported', async () => {
  for (const [args, options] of [
    [['add', 'button'], { isTTY: true, answer: false }],
    [['add', 'button', '--yes'], { isTTY: true }],
    [['add', 'button', '-y'], { isTTY: true }],
    [['add', 'button'], { isTTY: false }],
  ]) {
    const cwd = app()
    await cli(cwd, ['add', 'button'])
    writeFileSync(target(cwd, 'components/button.gts'), 'mine\n')
    const { output, questions } = await cli(cwd, args, options)
    assert.equal(
      readFileSync(target(cwd, 'components/button.gts'), 'utf8'),
      'mine\n',
      args.join(' '),
    )
    assert.match(output, /Skipped.*button\.gts/s, args.join(' '))
    if (!options.answer && args.length > 2) assert.deepEqual(questions, [])
  }
})

test('--overwrite (-o) replaces changed files without asking', async () => {
  for (const flag of ['--overwrite', '-o']) {
    const cwd = app()
    await cli(cwd, ['add', 'button'])
    writeFileSync(target(cwd, 'components/button.gts'), 'mine\n')
    const { questions } = await cli(cwd, ['add', 'button', flag], { isTTY: true })
    assert.deepEqual(questions, [])
    assert.equal(
      readFileSync(target(cwd, 'components/button.gts'), 'utf8'),
      source('components/button.gts'),
    )
  }
})

test('--dry-run lists what would happen and writes nothing', async () => {
  const cwd = app()
  const { output, installs } = await cli(cwd, ['add', 'dialog', '--dry-run'])
  assert.match(output, /create.*components\/dialog\.gts/)
  assert.match(output, /@ember-joinery\/primitives@\^1\.2\.0/)
  assert.deepEqual(installs, [])
  assert.ok(!existsSync(join(cwd, 'app')))
  assert.ok(!existsSync(join(cwd, 'joinery.json')))
})

test('--dry-run marks each file create, overwrite or unchanged', async () => {
  const cwd = app()
  await cli(cwd, ['add', 'dialog'])
  writeFileSync(target(cwd, 'components/button.gts'), 'mine\n')
  const { output } = await cli(cwd, ['add', 'dialog', '--dry-run'])
  assert.match(output, /overwrite.*components\/button\.gts/)
  assert.match(output, /unchanged.*components\/dialog\.gts/)
})

test('--diff shows each changed file against this version, and writes nothing', async () => {
  const cwd = app()
  await cli(cwd, ['add', 'dialog'])
  const mine = `${source('components/button.gts')}// mine\n`
  writeFileSync(target(cwd, 'components/button.gts'), mine)
  const { output } = await cli(cwd, ['add', 'dialog', '--diff'])
  assert.match(output, /--- .*components\/button\.gts/)
  assert.doesNotMatch(output, /--- .*components\/dialog\.gts/)
  assert.equal(readFileSync(target(cwd, 'components/button.gts'), 'utf8'), mine)
})

test('--diff <path> shows only that file', async () => {
  const cwd = app()
  await cli(cwd, ['add', 'dialog'])
  writeFileSync(target(cwd, 'components/button.gts'), 'mine\n')
  writeFileSync(target(cwd, 'components/icon.gts'), 'mine\n')
  const { output } = await cli(cwd, ['add', 'dialog', '--diff', 'icon.gts'])
  assert.match(output, /components\/icon\.gts/)
  assert.doesNotMatch(output, /components\/button\.gts/)
})

test('--diff without a path shows at most the first 5 files', async () => {
  const cwd = app()
  const { output } = await cli(cwd, ['add', '--all', '--diff'])
  assert.equal(output.match(/^--- /gm).length, 5)
  assert.match(output, /more/)
})

test('--view prints this version’s files, or the one named, and writes nothing', async () => {
  const cwd = app()
  const { output } = await cli(cwd, ['add', 'dialog', '--view', 'dialog.gts'])
  assert.ok(output.includes(source('components/dialog.gts')))
  assert.ok(!output.includes(source('components/button.gts')))
  assert.ok(!existsSync(join(cwd, 'app')))
})

test('--all (-a) adds every component', async () => {
  const cwd = app()
  await cli(cwd, ['add', '-a'])
  assert.ok(existsSync(target(cwd, 'components/sidebar.gts')))
  assert.ok(existsSync(target(cwd, 'components/accordion.gts')))
})

test('--cwd (-c) runs in another folder', async () => {
  const cwd = app()
  await cli(tmpdir(), ['add', 'badge', '-c', cwd])
  assert.ok(existsSync(target(cwd, 'components/badge.gts')))
})

test('--silent (-s) prints nothing', async () => {
  const { output } = await cli(app(), ['add', 'badge', '-s'])
  assert.equal(output, '')
})

test('an unknown component is an error that suggests the near names', async () => {
  const cwd = app()
  const { code, output } = await cli(cwd, ['add', 'dialgo'])
  assert.equal(code, 1)
  assert.match(output, /Unknown component "dialgo"/)
  assert.match(output, /dialog/)
  assert.ok(!existsSync(join(cwd, 'app')))
})

test('add with no names and no --all is an error', async () => {
  const { code, output } = await cli(app(), ['add'])
  assert.equal(code, 1)
  assert.match(output, /Name a component/)
})

test('list prints every component', async () => {
  const { code, output } = await cli(app(), ['list'])
  assert.equal(code, 0)
  assert.match(output, /^dialog$/m)
  assert.match(output, /^button$/m)
})

test('an app without TypeScript gets a warning: the copies are .gts', async () => {
  const { output } = await cli(app(), ['add', 'badge'])
  assert.match(output, /TypeScript/)
  const ts = app({ typescript: '^5.0.0' })
  assert.doesNotMatch((await cli(ts, ['add', 'badge'])).output, /TypeScript/)
})

test('unifiedDiff gives hunks with three lines of context', () => {
  const before = 'a\nb\nc\nd\ne\nf\ng\nh\n'
  const after = 'a\nb\nc\nd\nE\nf\ng\nh\n'
  assert.equal(
    unifiedDiff('x', before, after),
    '--- x (yours)\n+++ x (new)\n@@ -2,7 +2,7 @@\n b\n c\n d\n-e\n+E\n f\n g\n h\n',
  )
  assert.equal(unifiedDiff('x', before, before), '')
})
