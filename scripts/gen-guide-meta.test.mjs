import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync, existsSync, statSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { pageName, sectionOrder, writeGuideMeta } from './gen-guide-meta.mjs'

function templates(files) {
  const dir = mkdtempSync(join(tmpdir(), 'guide-meta-'))
  for (const [path, contents] of Object.entries(files)) {
    mkdirSync(join(dir, path, '..'), { recursive: true })
    writeFileSync(join(dir, path), contents)
  }
  return dir
}

test('pageName strips every page extension Kolay reads', () => {
  assert.equal(pageName('button.md'), 'button')
  assert.equal(pageName('alert-dialog.gts.md'), 'alert-dialog')
  assert.equal(pageName('chart.gjs.md'), 'chart')
  assert.equal(pageName('meta.json'), undefined)
  assert.equal(pageName('notes.txt'), undefined)
})

test('a section lists its pages and folders A–Z, without its index page', () => {
  const dir = templates({
    'components/toggle.md': '# Toggle',
    'components/button-group.md': '# Button Group',
    'components/button.md': '# Button',
    'components/alert-dialog.gts.md': '# Alert Dialog',
    'components/index.md': '# Components',
    'components/meta.json': '{ "order": [] }',
    'components/.DS_Store': '',
    'components/_draft.md': '# Draft',
    'components/charts/area.md': '# Area',
  })
  assert.deepEqual(sectionOrder(join(dir, 'components')), [
    'alert-dialog',
    'button',
    'button-group',
    'charts',
    'toggle',
  ])
})

test('writeGuideMeta writes each alphabetical section that exists, and only on a change', () => {
  const dir = templates({
    'components/button.md': '# Button',
    'components/badge.md': '# Badge',
    'getting-started/introduction.md': '# Introduction',
    'getting-started/meta.json': '{ "order": ["introduction"] }',
  })
  const written = writeGuideMeta({ templatesDir: dir, sections: ['components', 'primitives'] })
  assert.deepEqual(written, [join(dir, 'components', 'meta.json')])
  assert.deepEqual(JSON.parse(readFileSync(join(dir, 'components', 'meta.json'), 'utf8')), {
    order: ['badge', 'button'],
  })
  assert.equal(existsSync(join(dir, 'primitives')), false, 'a missing section is skipped')
  assert.equal(
    readFileSync(join(dir, 'getting-started', 'meta.json'), 'utf8'),
    '{ "order": ["introduction"] }',
    'hand-ordered sections are left alone',
  )

  const before = statSync(join(dir, 'components', 'meta.json')).mtimeMs
  assert.deepEqual(writeGuideMeta({ templatesDir: dir, sections: ['components'] }), [])
  assert.equal(statSync(join(dir, 'components', 'meta.json')).mtimeMs, before)

  writeFileSync(join(dir, 'components', 'accordion.md'), '# Accordion')
  assert.deepEqual(writeGuideMeta({ templatesDir: dir, sections: ['components'] }), [
    join(dir, 'components', 'meta.json'),
  ])
  assert.deepEqual(JSON.parse(readFileSync(join(dir, 'components', 'meta.json'), 'utf8')), {
    order: ['accordion', 'badge', 'button'],
  })
})
