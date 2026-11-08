import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import {
  collectModules,
  namedExports,
  pascalCase,
  renderBarrel,
  writeBarrels,
} from './gen-barrels.mjs'

/** A throwaway package directory holding the given files. */
function fixture(files) {
  const root = mkdtempSync(join(tmpdir(), 'gen-barrels-'))
  for (const [path, source] of Object.entries(files)) {
    mkdirSync(dirname(join(root, path)), { recursive: true })
    writeFileSync(join(root, path), source)
  }
  return root
}

const body = source => source.split('\n').filter(line => line && !line.startsWith('//'))

test('pascalCase turns file names into export names', () => {
  assert.equal(pascalCase('button'), 'Button')
  assert.equal(pascalCase('button-group'), 'ButtonGroup')
  assert.equal(pascalCase('input_otp'), 'InputOtp')
})

test('namedExports finds declarations, export lists and namespace re-exports', () => {
  const names = namedExports(
    [
      'export const a = 1',
      'export function b() {}',
      'export async function c() {}',
      'export class D {}',
      'export interface E {}',
      'export type F<T> = T',
      'export declare const g: number',
      'export const enum H {}',
      'const i = 1, j = 2',
      'export { i, j as J, type K }',
      "export * as ns from './ns.ts'",
      'export default class Z {}',
    ].join('\n'),
  )
  assert.deepEqual([...names].sort(), ['D', 'E', 'F', 'H', 'J', 'K', 'a', 'b', 'c', 'g', 'i', 'ns'])
})

test('a barrel exports every module: defaults by file name, named exports with export *', () => {
  const root = fixture({
    'src/components/button.gts':
      'export interface ButtonSignature {}\nexport default class Button {}\n',
    'src/components/button-group.gts': 'const ButtonGroup = 1\nexport default ButtonGroup\n',
    'src/utils.ts': 'export function cn() {}\n',
    'src/types.ts': 'export type Side = "top"\n',
  })
  try {
    assert.deepEqual(body(renderBarrel(join(root, 'src'))), [
      "export { default as ButtonGroup } from './components/button-group.gts'",
      "export { default as Button } from './components/button.gts'",
      "export * from './components/button.gts'",
      "export * from './types.ts'",
      "export * from './utils.ts'",
    ])
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('a folder with an index file is one module, and private names are skipped', () => {
  const root = fixture({
    'src/anchor/index.ts': "export { anchor } from './floating.ts'\n",
    'src/anchor/floating.ts': 'export function anchor() {}\n',
    'src/_internal.ts': 'export const secret = 1\n',
    'src/-private/state.ts': 'export const state = 1\n',
    'src/.hidden.ts': 'export const hidden = 1\n',
    'src/thing.test.ts': 'export const t = 1\n',
    'src/template-registry.ts': 'export default interface Registry {}\n',
    'src/types.d.ts': 'export type X = 1\n',
    'src/styles.css': '.a {}\n',
    'src/index.ts': '// an old barrel\nexport {}\n',
  })
  try {
    assert.deepEqual(collectModules(join(root, 'src')), ['anchor/index.ts'])
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('a default-exported interface is a type, not a value to re-export', () => {
  const root = fixture({ 'src/registry.ts': 'export default interface Registry {}\n' })
  try {
    assert.deepEqual(body(renderBarrel(join(root, 'src'))), ['export {}'])
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('an empty folder gets an empty module', () => {
  const root = fixture({ 'src/.gitkeep': '' })
  try {
    assert.deepEqual(body(renderBarrel(join(root, 'src'))), ['export {}'])
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('two modules exporting the same name fail with both paths', () => {
  const root = fixture({
    'src/a.ts': 'export const open = 1\n',
    'src/b.ts': 'export { x as open }\nconst x = 1\n',
  })
  try {
    assert.throws(
      () => renderBarrel(join(root, 'src')),
      /"open" is exported by both \.\/a\.ts and \.\/b\.ts/,
    )
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('a default export clashing with a named export fails', () => {
  const root = fixture({
    'src/button.gts': 'export default class Button {}\n',
    'src/legacy.ts': 'export const Button = 1\n',
  })
  try {
    assert.throws(() => renderBarrel(join(root, 'src')), /"Button" is exported by both/)
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('writeBarrels writes each configured folder and keeps nested barrels out of the parent', () => {
  const root = fixture({
    'package.json': JSON.stringify({ joinery: { barrels: ['src', 'src/test-support'] } }),
    'src/chart.gts': 'export default class Chart {}\n',
    'src/test-support/chart-harness.ts': 'export class ChartHarness {}\n',
  })
  try {
    const written = writeBarrels(root)
      .map(file => file.slice(root.length + 1))
      .sort()
    assert.deepEqual(written, ['src/index.ts', 'src/test-support/index.ts'])
    assert.deepEqual(body(readFileSync(join(root, 'src/index.ts'), 'utf8')), [
      "export { default as Chart } from './chart.gts'",
    ])
    assert.deepEqual(body(readFileSync(join(root, 'src/test-support/index.ts'), 'utf8')), [
      "export * from './chart-harness.ts'",
    ])
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('writeBarrels leaves an unchanged barrel untouched', () => {
  const root = fixture({
    'package.json': JSON.stringify({ joinery: { barrels: ['src'] } }),
    'src/a.ts': 'export const a = 1\n',
  })
  try {
    assert.equal(writeBarrels(root).length, 1)
    const before = statSync(join(root, 'src/index.ts')).mtimeMs
    assert.deepEqual(writeBarrels(root), [])
    assert.equal(statSync(join(root, 'src/index.ts')).mtimeMs, before)
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('a package without a barrels list is left alone', () => {
  const root = fixture({ 'package.json': JSON.stringify({ name: 'test-app' }) })
  try {
    assert.deepEqual(writeBarrels(root), [])
  } finally {
    rmSync(root, { recursive: true })
  }
})
