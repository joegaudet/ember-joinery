import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerButton from 'docs-app/examples/spinner-button'

module('Example | spinner-button', function (hooks) {
  setupRenderingTest(hooks)

  test('small disabled buttons, each with a spinner before its label', async function (assert) {
    await render(<template><SpinnerButton /></template>)
    const buttons = ButtonHarness.findAll()
    assert.deepEqual(
      buttons.map(button => button.label),
      ['Loading...', 'Please wait', 'Processing'],
    )
    assert.deepEqual(
      buttons.map(button => button.variant),
      ['default', 'outline', 'secondary'],
    )
    for (const button of buttons) {
      assert.strictEqual(button.size, 'sm')
      assert.true(button.isDisabled)
      const spinner = button.find(SpinnerHarness)
      assert.strictEqual(spinner.label, 'Loading')
      // Its own size-4, as upstream's: a small button's size-3.5 is for icons without one.
      assert.strictEqual(getComputedStyle(spinner.element).width, '16px')
      const box = button.element.getBoundingClientRect()
      assert.ok(
        spinner.element.getBoundingClientRect().left < box.left + box.width / 2,
        'at the inline start',
      )
    }
    await a11yAudit()
  })
})
