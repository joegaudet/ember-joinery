import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DrawerHarness, tab } from '@ember-joinery/test-support'
import DrawerScrollableContent from 'docs-app/examples/drawer-scrollable-content'

module('Example | drawer-scrollable-content', function (hooks) {
  setupRenderingTest(hooks)

  test('a drawer from the right whose text scrolls between its header and footer', async function (assert) {
    await render(<template><DrawerScrollableContent /></template>)
    const drawer = new DrawerHarness()
    assert.dom(drawer.trigger).hasText('Scrollable Content')
    await drawer.open()
    assert.strictEqual(drawer.direction, 'right')
    assert.strictEqual(drawer.label, 'Move Goal')
    assert.strictEqual(drawer.descriptionText, 'Set your daily activity goal.')
    drawer.finishAnimations()

    const content = drawer.content!
    const scroller = content.querySelector<HTMLElement>('.overflow-y-auto')!
    assert.strictEqual(scroller.querySelectorAll('p').length, 10)
    assert.ok(scroller.scrollHeight > scroller.clientHeight, 'the text scrolls')
    const footer = content.querySelector('[data-slot="drawer-footer"]')!
    assert.strictEqual(
      Math.round(footer.getBoundingClientRect().bottom),
      Math.round(content.getBoundingClientRect().bottom),
      'the footer stays at the bottom',
    )
    assert.dom(content).isFocused('focus is on the drawer')
    await tab()
    assert.dom(scroller).isFocused('then the text, which a keyboard can scroll')
    await a11yAudit()

    await drawer
      .findAll(ButtonHarness)
      .find(button => button.text === 'Cancel')!
      .click()
    assert.false(drawer.isOpen, 'Cancel closes it')
    assert.dom(drawer.trigger).isFocused()
    await a11yAudit()
  })
})
