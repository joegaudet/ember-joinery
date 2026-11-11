import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import Introduction from 'docs-app/examples/introduction'

/**
 * A harness drives a component the way a user does, and reads its state through ARIA, the way
 * a screen reader does. Joinery's components come with theirs (`ButtonHarness`…); this is
 * what one looks like inside, for the example's toggle.
 */
class ToggleButton extends Harness {
  static component = 'toggle' // its data-test-jn
  static named = 'bold' // its data-test-jn-name

  get isPressed() {
    return this.element.getAttribute('aria-pressed') === 'true'
  }

  async press() {
    await click(this.element)
  }
}

module('Example | introduction', function (hooks) {
  setupRenderingTest(hooks)

  test('pressing the toggle turns it on, and pressing it again turns it off', async function (assert) {
    await render(<template><Introduction /></template>)
    const bold = new ToggleButton()

    assert.dom(bold.element).hasText('Bold')
    assert.false(bold.isPressed)

    await bold.press()
    assert.true(bold.isPressed)
    assert.dom(bold.element).hasAttribute('data-state', 'on')

    await bold.press()
    assert.false(bold.isPressed)
    assert.dom(bold.element).hasAttribute('data-state', 'off')

    await a11yAudit()
  })
})
