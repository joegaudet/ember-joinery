import { module, test } from 'qunit'
import { indexPackage, type Reflection } from 'docs-app/api-reference'

const MODULE = 2
const VARIABLE = 32
const FUNCTION = 64
const CLASS = 128
const INTERFACE = 256
const REFERENCE = 4194304

/** A package as TypeDoc sees it: a barrel, component files, a folder module and a private one. */
const project: Reflection = {
  id: 0,
  name: 'pkg',
  kind: 1,
  children: [
    {
      id: 1,
      name: 'declarations',
      kind: MODULE,
      children: [
        // A default export the barrel names: TypeDoc declares it here.
        {
          id: 2,
          name: 'Alert',
          kind: VARIABLE,
          type: { type: 'reference', name: 'TOC', typeArguments: [] },
          comment: { summary: [{ kind: 'text', text: 'Displays a callout.\n\nMore.' }] },
        },
        { id: 3, name: 'anchorTo', kind: REFERENCE, target: 31 },
      ],
    },
    {
      id: 10,
      name: 'declarations/components/alert',
      kind: MODULE,
      children: [
        { id: 11, name: 'alert', kind: REFERENCE, target: 2 },
        { id: 12, name: 'AlertSignature', kind: INTERFACE },
      ],
    },
    {
      id: 20,
      name: 'declarations/components/button',
      kind: MODULE,
      children: [
        {
          id: 21,
          name: 'Button',
          kind: CLASS,
          extendedTypes: [
            {
              type: 'reference',
              name: 'default',
              package: '@glimmer/component',
              typeArguments: [{ type: 'reference', name: 'ButtonSignature', target: 22 }],
            },
          ],
        },
        { id: 22, name: 'ButtonSignature', kind: INTERFACE },
        { id: 23, name: 'buttonClasses', kind: FUNCTION },
      ],
    },
    // A folder module: its index re-exports what is public from the files beside it.
    {
      id: 30,
      name: 'declarations/anchor',
      kind: MODULE,
      children: [{ id: 32, name: 'anchorTo', kind: REFERENCE, target: 31 }],
    },
    {
      id: 33,
      name: 'declarations/anchor/modifier',
      kind: MODULE,
      children: [
        {
          id: 31,
          name: 'anchorTo',
          kind: VARIABLE,
          type: { type: 'reference', name: 'FunctionBasedModifier' },
        },
        { id: 34, name: 'internalHelper', kind: FUNCTION },
      ],
    },
    {
      id: 40,
      name: 'declarations/-private/parts',
      kind: MODULE,
      children: [{ id: 41, name: 'staticPart', kind: FUNCTION }],
    },
    {
      id: 50,
      name: 'declarations/test-support',
      kind: MODULE,
      children: [
        {
          id: 51,
          name: 'AlertHarness',
          kind: CLASS,
          extendedTypes: [
            { type: 'reference', name: 'Harness', package: '@ember-joinery/test-support' },
          ],
        },
      ],
    },
  ],
}

module('Unit | indexPackage', function () {
  const modules = indexPackage('@ember-joinery/ember', project)
  const byId = Object.fromEntries(modules.map(module => [module.id, module]))

  test('lists the public modules A–Z, without the barrel, private folders or files beside an index', function (assert) {
    assert.deepEqual(
      modules.map(module => module.id),
      ['anchor', 'components/alert', 'components/button', 'test-support'],
    )
  })

  test('a default export reads as the name the barrel gives it, and its docs are where it is declared', function (assert) {
    const [alert] = byId['components/alert']!.exports
    assert.deepEqual(alert, {
      name: 'Alert',
      kind: 'component',
      module: 'declarations',
      declaration: 'Alert',
      signature: undefined,
      summary: 'Displays a callout.',
    })
  })

  test('a component finds its signature interface, and the kinds sort components first', function (assert) {
    const button = byId['components/button']!
    assert.deepEqual(
      button.exports.map(entry => [entry.name, entry.kind]),
      [
        ['Button', 'component'],
        ['buttonClasses', 'function'],
        ['ButtonSignature', 'interface'],
      ],
    )
    assert.deepEqual(button.exports[0]!.signature, {
      module: 'declarations/components/button',
      name: 'ButtonSignature',
    })
  })

  test('a folder module shows what its index exports, from the files beside it', function (assert) {
    assert.deepEqual(byId['anchor']!.exports, [
      {
        name: 'anchorTo',
        kind: 'modifier',
        module: 'declarations/anchor/modifier',
        declaration: 'anchorTo',
        summary: undefined,
      },
    ])
  })

  test('test support is imported from the package’s /test-support, and a class names its base', function (assert) {
    const support = byId['test-support']!
    assert.strictEqual(support.importFrom, '@ember-joinery/ember/test-support')
    assert.strictEqual(support.exports[0]!.extends, 'Harness')
    assert.strictEqual(byId['components/button']!.importFrom, '@ember-joinery/ember')
    const harnesses = indexPackage('@ember-joinery/test-support', {
      ...project,
      children: [project.children![0]!, { ...project.children!.at(-1)!, name: 'dist/button' }],
    })
    assert.strictEqual(harnesses[0]!.importFrom, '@ember-joinery/test-support')
  })
})
