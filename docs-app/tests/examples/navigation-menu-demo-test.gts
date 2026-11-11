import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NavigationMenuHarness, pressKey, tab } from '@ember-joinery/test-support'
import NavigationMenuDemo from 'docs-app/examples/navigation-menu-demo'

module('Example | navigation-menu-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('two triggers with their links, and a link with a trigger’s look', async function (assert) {
    await render(<template><NavigationMenuDemo /></template>)
    const nav = new NavigationMenuHarness()
    assert.deepEqual(nav.triggerLabels, ['Getting started', 'Components'])
    assert.deepEqual(nav.listLinks, ['Docs'])
    assert.dom(nav.listLink('Docs')).hasClass('jn-navigation-menu-trigger')
    await a11yAudit()

    const start = nav.item('Getting started')
    await start.hover()
    assert.true(start.isOpen, 'the pointer resting on a trigger opens it')
    assert.strictEqual(start.links.length, 3)
    assert.dom(start.link('Introduction')).hasAttribute('href', '/docs')
    assert.dom(start.link('Installation')).hasText(/How to install dependencies/)
    assert.ok(nav.viewport!.contains(start.content), 'in the viewport')
    await a11yAudit()

    const components = nav.item('Components')
    await components.hover()
    assert.true(components.isOpen, 'moving to another trigger opens it at once')
    assert.strictEqual(components.motion, 'from-end')
    assert.deepEqual(
      components.linkElements.map(link => link.querySelector('.font-medium')!.textContent),
      ['Alert Dialog', 'Hover Card', 'Progress', 'Scroll-area', 'Tabs', 'Tooltip'],
    )
    await a11yAudit()
  })

  test('the keyboard: Enter, then Tab into the links, and Escape', async function (assert) {
    await render(<template><NavigationMenuDemo /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.openWithKeyboard()
    await tab()
    assert.strictEqual(
      nav.focused,
      'Introduction Re-usable components built with Tailwind CSS.',
      'Tab goes into the content',
    )
    await pressKey('ArrowDown')
    assert.dom(start.link('Installation')).isFocused()
    await nav.pressEscape()
    assert.false(start.isOpen)
    assert.dom(start.trigger).isFocused()
    await a11yAudit()
  })
})
