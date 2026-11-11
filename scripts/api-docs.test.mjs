import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, readdirSync, existsSync } from 'node:fs'
import { join } from 'node:path'
import {
  KIND,
  apiDocsFile,
  fenceIndentedCode,
  isApiDocsPath,
  refineApiDocs,
} from '../docs-app/api-docs.mjs'

const root = join(import.meta.dirname, '..')

const module = (id, name, children) => ({ id, name, kind: KIND.Module, children })

test('the file Kolay writes for a package is the one the plugin refines', () => {
  assert.equal(apiDocsFile('@ember-joinery/ember'), 'docs/@ember-joinery__ember.json')
  const packages = ['@ember-joinery/ember']
  assert.ok(isApiDocsPath('docs/@ember-joinery__ember.json', packages))
  assert.ok(isApiDocsPath('/ember-joinery/guide/docs/@ember-joinery__ember.json', packages))
  assert.ok(!isApiDocsPath('docs/@ember-joinery__chart.json', packages))
  assert.ok(!isApiDocsPath('getting-started/introduction.md', packages))
})

test('the module that declares things keeps a name TypeDoc gave two modules', () => {
  const stub = module(1, 'declarations/components/carousel', [
    { id: 2, name: 'default', kind: KIND.Reference, target: 4 },
  ])
  const index = module(3, 'declarations/components/carousel', [
    { id: 4, name: 'Carousel', kind: KIND.Class },
  ])
  const project = refineApiDocs({ id: 0, name: 'x', kind: 1, children: [stub, index] })
  assert.deepEqual(
    project.children.map(child => child.name),
    ['declarations/components/carousel (re-exports)', 'declarations/components/carousel'],
  )
})

test('a class keeps its own members, and an accessor reads as a property', () => {
  const harness = {
    id: 10,
    name: 'ButtonHarness',
    kind: KIND.Class,
    extendedTypes: [{ type: 'reference', name: 'Harness' }],
    children: [
      { id: 11, name: 'element', kind: KIND.Accessor, inheritedFrom: { type: 'reference' } },
      {
        id: 12,
        name: 'label',
        kind: KIND.Accessor,
        getSignature: {
          id: 13,
          name: 'label',
          type: { type: 'intrinsic', name: 'string' },
          comment: { summary: [{ kind: 'text', text: 'Its accessible name.' }] },
        },
      },
      { id: 14, name: 'click', kind: KIND.Method, signatures: [] },
    ],
    groups: [{ title: 'Accessors', children: [11, 12] }],
  }
  refineApiDocs({ id: 0, name: 'x', kind: 1, children: [module(1, 'dist/button', [harness])] })
  assert.deepEqual(
    harness.children.map(child => child.name),
    ['label', 'click'],
    'the inherited `element` is gone',
  )
  assert.deepEqual(harness.groups, [{ title: 'Accessors', children: [12] }])
  const label = harness.children[0]
  assert.equal(label.kind, KIND.Property)
  assert.deepEqual(label.type, { type: 'intrinsic', name: 'string' })
  assert.equal(label.comment.summary[0].text, 'Its accessible name.')
  assert.equal(label.flags.isReadonly, true, 'a getter with no setter')
  assert.equal(label.getSignature, undefined)
})

test("a signature's Args intersection becomes one object type with every argument", () => {
  const options = {
    id: 20,
    name: 'ButtonOptions',
    kind: KIND.Interface,
    children: [
      { id: 21, name: 'variant', kind: KIND.Property, flags: { isOptional: true } },
      { id: 22, name: 'size', kind: KIND.Property, flags: { isOptional: true } },
    ],
  }
  const args = {
    id: 31,
    name: 'Args',
    kind: KIND.Property,
    type: {
      type: 'intersection',
      types: [
        { type: 'reference', name: 'ButtonOptions', target: 20 },
        {
          type: 'reflection',
          declaration: {
            id: 32,
            name: '__type',
            kind: KIND.TypeLiteral,
            children: [{ id: 33, name: 'as', kind: KIND.Property }],
          },
        },
      ],
    },
  }
  const signature = { id: 30, name: 'ButtonSignature', kind: KIND.Interface, children: [args] }
  refineApiDocs({
    id: 0,
    name: 'x',
    kind: 1,
    children: [module(1, 'declarations/components/button', [options, signature])],
  })
  assert.equal(args.type.type, 'reflection')
  const merged = args.type.declaration.children
  assert.deepEqual(
    merged.map(child => child.name),
    ['variant', 'size', 'as'],
  )
  const ids = merged.map(child => child.id)
  assert.ok(
    ids.every(id => id > 33),
    'the copies have ids of their own, so the originals keep theirs',
  )
  assert.deepEqual(
    options.children.map(child => child.id),
    [21, 22],
  )

  // An intersection with a part from outside the package stays as it is.
  const outside = {
    id: 40,
    name: 'Args',
    kind: KIND.Property,
    type: { type: 'intersection', types: [{ type: 'reference', name: 'Partial' }] },
  }
  refineApiDocs({ id: 0, name: 'x', kind: 1, children: [module(1, 'declarations/a', [outside])] })
  assert.equal(outside.type.type, 'intersection')
})

test("a comment's indented examples become fenced code", () => {
  assert.equal(
    fenceIndentedCode(
      'Displays a button:\n\n  <Button @variant="outline" {{on "click" this.save}}>Save</Button>\n\nIt submits.',
    ),
    'Displays a button:\n\n```hbs\n<Button @variant="outline" {{on "click" this.save}}>Save</Button>\n```\n\nIt submits.',
  )
  assert.equal(
    fenceIndentedCode('Usage:\n\n    const a = 1\n      b()'),
    'Usage:\n\n```ts\nconst a = 1\n  b()\n```',
    'dedented by the block’s own indent',
  )
  assert.equal(
    fenceIndentedCode('A line\n  that continues, indented'),
    'A line\n  that continues, indented',
    'an indented line straight after text continues its paragraph',
  )
  assert.equal(fenceIndentedCode('```ts\n  kept()\n```'), '```ts\n  kept()\n```', 'fences stay')

  const comment = {
    summary: [
      { kind: 'text', text: 'Renders a ' },
      { kind: 'code', text: '`<button>`' },
      { kind: 'text', text: ':\n\n  <Button>Save</Button>' },
    ],
  }
  refineApiDocs({
    id: 0,
    name: 'x',
    kind: 1,
    children: [module(1, 'declarations/b', [{ id: 2, name: 'B', kind: KIND.Class, comment }])],
  })
  assert.deepEqual(comment.summary, [
    { kind: 'text', text: 'Renders a `<button>`:\n\n```hbs\n<Button>Save</Button>\n```' },
  ])
})

const publishedPackages = readdirSync(join(root, 'packages'))
  .filter(dir => existsSync(join(root, 'packages', dir, 'package.json')))
  .map(dir => ({ dir, ...JSON.parse(readFileSync(join(root, 'packages', dir, 'package.json'))) }))
  .filter(pkg => !pkg.private)

test('every published package has a Reference page, and the guide documents it', () => {
  const config = readFileSync(join(root, 'docs-app/vite.config.mjs'), 'utf8')
  const listed = config.match(/const API_PACKAGES = \[([^\]]*)\]/)[1]
  for (const pkg of publishedPackages) {
    assert.ok(listed.includes(`'${pkg.name}'`), `${pkg.name} is in API_PACKAGES`)
    const page = join(root, 'docs-app/app/templates/reference', `${pkg.dir}.md`)
    assert.ok(existsSync(page), `reference/${pkg.dir}.md exists`)
    assert.match(
      readFileSync(page, 'utf8'),
      new RegExp(`<PackageReference @package="${pkg.name.replace('/', '\\/')}" />`),
      `reference/${pkg.dir}.md renders ${pkg.name}`,
    )
    assert.match(
      readFileSync(join(root, 'docs-app/app/templates/reference/index.md'), 'utf8'),
      new RegExp(`\\(/reference/${pkg.dir}\\.md\\)`),
      `the overview links ${pkg.dir}`,
    )
  }
})
