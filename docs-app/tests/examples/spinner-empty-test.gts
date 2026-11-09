import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, EmptyHarness, SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerEmpty from 'docs-app/examples/spinner-empty'

module('Example | spinner-empty', function (hooks) {
  setupRenderingTest(hooks)

  test('a spinner as the empty state media', async function (assert) {
    await render(<template><SpinnerEmpty /></template>)
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, 'Processing your request')
    assert.strictEqual(empty.mediaVariant, 'icon')
    const spinner = empty.find(SpinnerHarness)
    assert.strictEqual(spinner.label, 'Loading')
    assert.ok(empty.media.contains(spinner.element), 'in the media tile')
    assert.strictEqual(getComputedStyle(spinner.element).width, '16px', 'its own size-4')
    const cancel = empty.find(ButtonHarness)
    assert.strictEqual(cancel.label, 'Cancel')
    assert.strictEqual(cancel.size, 'sm')
    await a11yAudit()
  })
})
