import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import VisuallyHiddenIconButton from 'docs-app/examples/visually-hidden-icon-button'

/**
 * The icon button. Its label is a part inside VisuallyHidden, which isn't a component root, so
 * the label still belongs to the button.
 */
class IconButtonHarness extends Harness {
  static component = 'icon-button'

  /** The button's text, as a screen reader would name it. */
  get name() {
    return this.element.textContent!.trim()
  }

  get label() {
    return this.part('label')
  }
}

module('Example | visually-hidden-icon-button', function (hooks) {
  setupRenderingTest(hooks)

  test('the button is named by text no one sees', async function (assert) {
    await render(<template><VisuallyHiddenIconButton /></template>)
    const close = new IconButtonHarness()
    assert.strictEqual(close.name, 'Close')
    assert.strictEqual(getComputedStyle(close.label).position, 'absolute')
    assert.ok(close.label.getBoundingClientRect().width <= 1, 'it takes no room')
    // The accessible name comes from the hidden text, so the audit passes.
    await a11yAudit()
  })
})
