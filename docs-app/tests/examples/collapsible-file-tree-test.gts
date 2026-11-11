import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  CardHarness,
  CollapsibleHarness,
  TabsHarness,
  child,
} from '@ember-joinery/test-support'
import CollapsibleFileTree from 'docs-app/examples/collapsible-file-tree'

/** The file tree: a page object, with its tabs and its folders and files found by name. */
class FileTree extends CardHarness {
  @child(TabsHarness) declare tabs: TabsHarness

  /** The folders shown now (each a collapsible), by name. */
  get folders(): string[] {
    return this.findAll(CollapsibleHarness)
      .filter(folder => folder.trigger.checkVisibility())
      .map(folder => folder.label)
  }

  /** The files shown now (each a link Button), by name. */
  get files(): string[] {
    return this.findAll(ButtonHarness)
      .filter(button => button.variant === 'link' && button.element.checkVisibility())
      .map(button => button.label)
  }

  /** The folder with this name. */
  folder(name: string): CollapsibleHarness {
    const folder = this.findAll(CollapsibleHarness).find(each => each.label === name)
    if (!folder) throw new Error(`no folder named ${name}`)
    return folder
  }
}

const TOP_FILES = [
  'app.tsx',
  'layout.tsx',
  'globals.css',
  'package.json',
  'tsconfig.json',
  'README.md',
  '.gitignore',
]

module('Example | collapsible-file-tree', function (hooks) {
  setupRenderingTest(hooks)

  test('folders open into their files, one level at a time', async function (assert) {
    await render(<template><CollapsibleFileTree /></template>)
    const tree = new FileTree()
    assert.strictEqual(tree.size, 'sm')
    assert.deepEqual(
      tree.tabs.tabValues.map(value => tree.tabs.label(value)),
      ['Explorer', 'Outline'],
    )
    assert.strictEqual(tree.tabs.selected, 'explorer')
    const header = getComputedStyle(tree.header)
    assert.strictEqual(
      tree.tabs.list.offsetWidth,
      tree.header.clientWidth - parseFloat(header.paddingLeft) - parseFloat(header.paddingRight),
      'the list is w-full, across the header',
    )

    assert.deepEqual(tree.folders, ['components', 'lib', 'hooks', 'types', 'public'])
    assert.deepEqual(tree.files, TOP_FILES)

    const components = tree.folder('components')
    assert.false(components.isOpen)
    const chevron = components.trigger.querySelector('svg')!
    assert.strictEqual(getComputedStyle(chevron).rotate, 'none', 'the chevron points right')
    await components.open()
    assert.true(components.isOpen)
    // It turns with transition-transform; read where the turn ends.
    for (const animation of chevron.getAnimations()) animation.finish()
    assert.strictEqual(getComputedStyle(chevron).rotate, '90deg', 'and down once it is open')
    assert.deepEqual(tree.folders, ['components', 'ui', 'lib', 'hooks', 'types', 'public'])
    assert.deepEqual(tree.files, ['login-form.tsx', 'register-form.tsx', ...TOP_FILES])
    assert.strictEqual(getComputedStyle(components.content!).marginLeft, '20px', 'ml-5')

    await tree.folder('ui').open()
    assert.deepEqual(tree.files.slice(0, 6), [
      'button.tsx',
      'card.tsx',
      'dialog.tsx',
      'input.tsx',
      'select.tsx',
      'table.tsx',
    ])

    await components.close()
    assert.deepEqual(tree.files, TOP_FILES, 'closing a folder hides what is in it')
    await a11yAudit()
  })

  test("in Lyra, a folder's content is indented less, as upstream's style-lyra:ml-4", async function (assert) {
    await render(
      <template>
        <div data-style="lyra"><CollapsibleFileTree /></div>
      </template>,
    )
    const tree = new FileTree()
    const lib = tree.folder('lib')
    await lib.open()
    assert.deepEqual(tree.files.slice(0, 3), ['utils.ts', 'cn.ts', 'api.ts'])
    assert.strictEqual(getComputedStyle(lib.content!).marginLeft, '16px', 'ml-4')
    await a11yAudit()
  })
})
