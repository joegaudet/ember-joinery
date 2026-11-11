// Every published package's tarball carries the root's LICENSE.md and NOTICE: its `files` list
// both, and its `prepack`, which every pack runs, copies them in from the root first.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import { LEGAL_FILES, ROOT, copyLegalFiles } from './legal-files.mjs'

const SCRIPT = join(ROOT, 'scripts', 'legal-files.mjs')
const STEP = 'node ../../scripts/legal-files.mjs .'

const packages = readdirSync(join(ROOT, 'packages'))
  .map(dir => ({
    dir,
    manifest: JSON.parse(readFileSync(join(ROOT, 'packages', dir, 'package.json'), 'utf8')),
  }))
  .filter(({ manifest }) => !manifest.private)

test('there are published packages to check', () => {
  assert.ok(packages.length >= 12, `found ${packages.length}`)
})

for (const { dir, manifest } of packages) {
  test(`${manifest.name} lists the legal files and copies them in before it packs`, () => {
    for (const file of LEGAL_FILES) {
      assert.ok(manifest.files.includes(file), `"files" lists ${file}`)
    }
    const steps = (manifest.scripts?.prepack ?? '').split('&&').map(step => step.trim())
    assert.ok(steps.includes(STEP), `packages/${dir}'s prepack runs \`${STEP}\``)
  })
}

test('copyLegalFiles copies the root files unchanged, over any stale copy', () => {
  const dir = mkdtempSync(join(tmpdir(), 'joinery-legal-'))
  try {
    writeFileSync(join(dir, 'NOTICE'), 'stale')
    copyLegalFiles(dir)
    for (const file of LEGAL_FILES) {
      assert.equal(readFileSync(join(dir, file), 'utf8'), readFileSync(join(ROOT, file), 'utf8'))
    }
  } finally {
    rmSync(dir, { recursive: true, force: true })
  }
})

test('a pack runs the prepack and puts both files in the tarball', () => {
  const dir = mkdtempSync(join(tmpdir(), 'joinery-legal-pack-'))
  const out = mkdtempSync(join(tmpdir(), 'joinery-legal-out-'))
  try {
    writeFileSync(
      join(dir, 'package.json'),
      JSON.stringify({
        name: 'legal-files-fixture',
        version: '1.0.0',
        files: ['index.js', ...LEGAL_FILES],
        scripts: { prepack: `node ${JSON.stringify(SCRIPT)} .` },
      }),
    )
    writeFileSync(join(dir, 'index.js'), '')
    // npm runs `prepack` as pnpm does (publish.mjs packs with pnpm, which isn't always on PATH).
    execFileSync('npm', ['pack', '--pack-destination', out, '--silent'], {
      cwd: dir,
      stdio: 'pipe',
    })
    const tarball = join(out, 'legal-files-fixture-1.0.0.tgz')
    const listed = execFileSync('tar', ['-tzf', tarball], { encoding: 'utf8' }).split('\n')
    for (const file of LEGAL_FILES) assert.ok(listed.includes(`package/${file}`), file)
    const notice = execFileSync('tar', ['-xzOf', tarball, 'package/NOTICE'], { encoding: 'utf8' })
    assert.equal(notice, readFileSync(join(ROOT, 'NOTICE'), 'utf8'))
  } finally {
    rmSync(dir, { recursive: true, force: true })
    rmSync(out, { recursive: true, force: true })
  }
})
