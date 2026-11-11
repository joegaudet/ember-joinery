import { test } from 'node:test'
import assert from 'node:assert/strict'
import { existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import {
  declaresDefault,
  entryFileName,
  entrypoints,
  folderTypes,
  publicModules,
  writeFolderTypes,
} from './entrypoints.mjs'

/** A throwaway package directory holding the given files. */
function fixture(files) {
  const root = mkdtempSync(join(tmpdir(), 'entrypoints-'))
  for (const [path, source] of Object.entries(files)) {
    mkdirSync(dirname(join(root, path)), { recursive: true })
    writeFileSync(join(root, path), source)
  }
  return root
}

const body = source => source.split('\n').filter(line => line && !line.startsWith('//'))

test('a module builds to its path; a folder feature to the folder name', () => {
  assert.equal(entryFileName('index.ts'), 'index.js')
  assert.equal(entryFileName('visually-hidden.gts'), 'visually-hidden.js')
  assert.equal(entryFileName('components/button.gts'), 'components/button.js')
  assert.equal(entryFileName('anchor/index.ts'), 'anchor.js')
  assert.equal(entryFileName('components/dialog/index.gts'), 'components/dialog.js')
  assert.equal(entryFileName('test-support/index.js'), 'test-support.js')
})

test('the entrypoints are the barrel modules, the barrels and template-registry', () => {
  const root = fixture({
    'src/index.ts': 'export {}\n',
    'src/template-registry.ts': 'export default interface Registry {}\n',
    'src/visually-hidden.gts': 'export default 1\n',
    'src/anchor/index.ts': "export * from './floating.ts'\n",
    'src/anchor/floating.ts': 'export function anchor() {}\n',
    'src/components/button.gts': 'export default 1\n',
    'src/components/dialog/index.gts': 'export default 1\n',
    'src/components/dialog/parts.gts': 'export const Title = 1\n',
    'src/test-support/index.ts': "export * from './harness.ts'\n",
    'src/test-support/harness.ts': 'export class Harness {}\n',
    'src/-private/state.ts': 'export const state = 1\n',
    'src/components/-private/shared.ts': 'export const shared = 1\n',
    'src/_internal.ts': 'export const secret = 1\n',
    'src/.hidden.ts': 'export const hidden = 1\n',
    'src/thing.test.ts': 'export const t = 1\n',
    'src/types.d.ts': 'export type X = 1\n',
    'src/joinery.css': '.a {}\n',
  })
  try {
    assert.deepEqual(publicModules(join(root, 'src')), [
      { source: 'anchor/index.ts', fileName: 'anchor.js' },
      { source: 'components/button.gts', fileName: 'components/button.js' },
      { source: 'components/dialog/index.gts', fileName: 'components/dialog.js' },
      { source: 'index.ts', fileName: 'index.js' },
      { source: 'template-registry.ts', fileName: 'template-registry.js' },
      { source: 'test-support/index.ts', fileName: 'test-support.js' },
      { source: 'visually-hidden.gts', fileName: 'visually-hidden.js' },
    ])
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('a file and a folder feature with the same name fail with both paths', () => {
  const root = fixture({
    'src/anchor.ts': 'export const a = 1\n',
    'src/anchor/index.ts': 'export const b = 1\n',
  })
  try {
    assert.throws(
      () => publicModules(join(root, 'src')),
      /src\/anchor\/index\.ts and .*src\/anchor\.ts are both the subpath anchor/,
    )
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('declaresDefault finds default exports in declaration files', () => {
  assert.equal(declaresDefault('export default class Dialog {}\n'), true)
  assert.equal(
    declaresDefault('declare const _default: TOC<{}>;\nexport default _default;\n'),
    true,
  )
  assert.equal(declaresDefault('export default interface Registry {}\n'), true)
  assert.equal(declaresDefault("export { default } from './dialog';\n"), true)
  assert.equal(declaresDefault("export { Root, default } from './dialog';\n"), true)
  assert.equal(declaresDefault('declare const Root: 1;\nexport { Root as default };\n'), true)
  assert.equal(declaresDefault("export { default as Dialog } from './dialog';\n"), false)
  assert.equal(declaresDefault('export declare function anchor(): void;\n'), false)
  assert.equal(declaresDefault('export {};\n'), false)
})

test("a folder feature's types re-export its index, with the default when it has one", () => {
  assert.deepEqual(body(folderTypes('anchor/index.ts', 'export declare const a: 1;\n')), [
    "export * from './anchor/index.js'",
  ])
  assert.deepEqual(
    body(folderTypes('components/dialog/index.gts', 'export default class Dialog {}\n')),
    ["export * from './dialog/index.js'", "export { default } from './dialog/index.js'"],
  )
})

test('writeFolderTypes writes each folder feature beside its folder, once', () => {
  const root = fixture({
    'src/index.ts': 'export {}\n',
    'src/button.gts': 'export default 1\n',
    'src/anchor/index.ts': 'export const a = 1\n',
    'src/dialog/index.gts': 'export default 1\n',
    'declarations/index.d.ts': 'export {};\n',
    'declarations/button.d.ts': 'declare const _default: 1;\nexport default _default;\n',
    'declarations/anchor/index.d.ts': 'export declare const a = 1;\n',
    // No declarations/dialog/index.d.ts: as when ember-tsc fails.
  })
  try {
    const src = join(root, 'src')
    const declarations = join(root, 'declarations')
    assert.deepEqual(writeFolderTypes(src, declarations), [join(declarations, 'anchor.d.ts')])
    assert.deepEqual(body(readFileSync(join(declarations, 'anchor.d.ts'), 'utf8')), [
      "export * from './anchor/index.js'",
    ])
    assert.equal(existsSync(join(declarations, 'dialog.d.ts')), false)
    assert.deepEqual(writeFolderTypes(src, declarations), [], 'unchanged files are left alone')
  } finally {
    rmSync(root, { recursive: true })
  }
})

test('the plugin emits a chunk per entrypoint and writes types after the earlier plugins', () => {
  const root = fixture({
    'src/index.ts': 'export {}\n',
    'src/anchor/index.ts': 'export const a = 1\n',
    'src/anchor/floating.ts': 'export const f = 1\n',
  })
  try {
    const plugin = entrypoints({
      srcDir: join(root, 'src'),
      declarationsDir: join(root, 'declarations'),
    })
    const emitted = []
    const watched = []
    plugin.buildStart.call({
      emitFile: file => emitted.push(file),
      addWatchFile: file => watched.push(file),
    })
    assert.deepEqual(emitted, [
      { type: 'chunk', id: join(root, 'src/anchor/index.ts'), fileName: 'anchor.js' },
      { type: 'chunk', id: join(root, 'src/index.ts'), fileName: 'index.js' },
    ])
    assert.deepEqual(watched, [join(root, 'src/anchor/index.ts'), join(root, 'src/index.ts')])
    assert.equal(plugin.writeBundle.sequential, true, 'waits for addon.declarations() to finish')
  } finally {
    rmSync(root, { recursive: true })
  }
})
