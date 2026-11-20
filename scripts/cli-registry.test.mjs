import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, readFileSync, readdirSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { buildRegistry, imports } from '../packages/cli/lib/build-registry.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const src = join(root, 'packages/ember/src')

function build(version) {
  const out = mkdtempSync(join(tmpdir(), 'cli-registry-'))
  buildRegistry({ emberDir: join(root, 'packages/ember'), outDir: out, version })
  return { out, manifest: JSON.parse(readFileSync(join(out, 'manifest.json'), 'utf8')) }
}

test('every component in @ember-joinery/ember is an item', () => {
  const { manifest } = build('1.2.0')
  const components = readdirSync(join(src, 'components'))
    .filter(name => name.endsWith('.gts'))
    .map(name => name.slice(0, -'.gts'.length))
  assert.deepEqual(Object.keys(manifest.items).sort(), components.sort())
})

test('an item lists its file, the -private files it imports, and the components it needs', () => {
  const { manifest } = build('1.2.0')
  const dialog = manifest.items.dialog
  assert.equal(dialog.files[0], 'components/dialog.gts')
  assert.ok(dialog.registryDependencies.includes('button'))
  assert.ok(dialog.registryDependencies.includes('icon'))
  assert.ok(dialog.dependencies.includes('@ember-joinery/primitives'))
  assert.ok(dialog.dependencies.includes('lucide'), "dialog imports lucide's X")
  // Icon takes its icon as an argument: it imports nothing from lucide, though its comments do.
  assert.deepEqual(manifest.items.icon.dependencies, [])
})

test('every relative import is covered: by a file of the item or by one of its components', () => {
  const { out, manifest } = build('1.2.0')
  for (const [name, item] of Object.entries(manifest.items)) {
    const own = new Set(item.files)
    for (const file of item.files) {
      const source = readFileSync(join(out, 'files', file), 'utf8')
      for (const spec of imports(source).filter(spec => spec.startsWith('.'))) {
        const target = join(dirname(file), spec)
        const component = target.match(/^components\/(.+)\.gts$/)?.[1]
        assert.ok(
          own.has(target) || (component && item.registryDependencies.includes(component)),
          `${name}: ${file} imports ${spec}, which the item doesn't cover`,
        )
      }
    }
    for (const dep of item.registryDependencies) assert.ok(manifest.items[dep], `${name}: ${dep}`)
  }
})

test('no copied file imports @ember-joinery/ember, which a copy replaces', () => {
  const { out, manifest } = build('1.2.0')
  for (const item of Object.values(manifest.items)) {
    for (const file of item.files) {
      const source = readFileSync(join(out, 'files', file), 'utf8')
      assert.doesNotMatch(
        source,
        /^\s*(?:import|export)\b[^\n]*from '@ember-joinery\/ember['/]/m,
        file,
      )
    }
  }
})

test('the copies are the package source, byte for byte', () => {
  const { out } = build('1.2.0')
  assert.equal(
    readFileSync(join(out, 'files/components/dialog.gts'), 'utf8'),
    readFileSync(join(src, 'components/dialog.gts'), 'utf8'),
  )
})

test('npm packages: primitives at this version, the rest at the ranges the package uses', () => {
  const { manifest } = build('1.2.0')
  const ember = JSON.parse(readFileSync(join(root, 'packages/ember/package.json'), 'utf8'))
  assert.equal(manifest.version, '1.2.0')
  assert.deepEqual(manifest.dependencies, {
    '@ember-joinery/primitives': '^1.2.0',
    lucide: ember.dependencies.lucide,
  })
})

test('the import scanner reads single and double quotes, and multi-line imports', () => {
  assert.deepEqual(
    imports(
      `import a from "./a.gts"\nimport {\n  b, // it's b\n} from '@x/y/z'\nexport * from './c.ts'\nimport './d.css'\n`,
    ),
    ['./a.gts', '@x/y/z', './c.ts', './d.css'],
  )
})
