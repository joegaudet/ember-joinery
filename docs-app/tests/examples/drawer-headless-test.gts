import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DrawerHarness, tab } from '@ember-joinery/test-support'
import DrawerHeadless from 'docs-app/examples/drawer-headless'

module('Example | drawer-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the behaviour, with your own look', async function (assert) {
    await render(<template><DrawerHeadless /></template>)
    const drawer = new DrawerHarness()
    await drawer.open()
    assert.true(drawer.isInTopLayer)
    assert.true(drawer.isModal)
    assert.strictEqual(drawer.label, 'Move goal')
    assert.dom(drawer.handle).hasAttribute('data-vaul-handle', '')
    assert.dom(drawer.content).isFocused()
    await tab()
    assert.dom(drawer.part('close')).isFocused('Tab goes to Done')
    await a11yAudit()

    await drawer.afterOpening()
    await drawer.drag(30)
    assert.true(drawer.isOpen, 'a short drag springs back')
    assert.dom(drawer.description).hasText('Drag me down to close me: 0% of the way.')
    await click(drawer.part('close'))
    assert.false(drawer.isOpen)
    assert.dom(drawer.trigger).isFocused()
    await a11yAudit()
  })
})
