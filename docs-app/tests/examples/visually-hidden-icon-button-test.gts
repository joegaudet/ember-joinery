import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import VisuallyHiddenIconButton from 'docs-app/examples/visually-hidden-icon-button'

module('Example | visually-hidden-icon-button', function (hooks) {
  setupRenderingTest(hooks)

  test('the button is named by text no one sees', async function (assert) {
    await render(<template><VisuallyHiddenIconButton /></template>)
    // The accessible name comes from the hidden text, so the audit passes.
    assert.dom('button').hasText('Close')
    const label = find('[data-slot="visually-hidden"]')!
    assert.strictEqual(getComputedStyle(label).position, 'absolute')
    assert.ok(label.getBoundingClientRect().width <= 1, 'it takes no room')
    await a11yAudit()
  })
})
