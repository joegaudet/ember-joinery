import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import PresenceFade from 'docs-app/examples/presence-fade'

/** The example: a toggle button, and the panel it shows and hides. */
class FadingPanelHarness extends Harness {
  static component = 'fading-panel'

  get toggle() {
    return this.part('toggle')
  }

  /** The panel, or `null` once it has gone. */
  get panel() {
    return this.queryPart('panel')
  }

  get isOpen() {
    return this.toggle.getAttribute('aria-expanded') === 'true'
  }

  async press() {
    await click(this.toggle)
  }
}

module('Example | presence-fade', function (hooks) {
  setupRenderingTest(hooks)

  test('the panel animates out, then goes', async function (assert) {
    await render(<template><PresenceFade /></template>)
    const example = new FadingPanelHarness()
    assert.dom(example.panel).hasAttribute('data-state', 'open')

    // click() waits until the page settles, and Presence holds that until the exit ends.
    await example.press()
    assert.false(example.isOpen)
    assert.strictEqual(example.panel, null, 'gone once its exit animation ended')
    assert.dom(example.toggle).hasText('Show')

    await example.press()
    assert.dom(example.panel).exists().hasAttribute('data-state', 'open')
    await a11yAudit()
  })
})
