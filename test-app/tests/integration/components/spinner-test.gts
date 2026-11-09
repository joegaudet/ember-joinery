import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Spinner } from '@ember-joinery/ember'
import { SpinnerHarness } from '@ember-joinery/test-support'

module('Integration | components | spinner', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a turning loader-circle with the status role', async function (assert) {
    await render(
      <template>
        <Spinner />
        <Spinner @name="saving" @label="Saving" data-icon="inline-start" />
      </template>,
    )
    const spinner = new SpinnerHarness()
    assert.strictEqual(spinner.role, 'status')
    assert.strictEqual(spinner.label, 'Loading', 'an English default')
    assert
      .dom(spinner.element)
      .hasTagName('svg')
      .hasClass('jn-spinner')
      .hasAttribute('data-slot', 'spinner')
      .doesNotHaveAttribute('aria-hidden')
    const style = getComputedStyle(spinner.element)
    assert.strictEqual(style.width, '16px', 'size-4')
    assert.ok(style.animationName.includes('spin'), 'animate-spin')

    const saving = new SpinnerHarness('saving')
    assert.strictEqual(saving.label, 'Saving')
    assert.dom(saving.element).hasAttribute('data-icon', 'inline-start')
    await a11yAudit()
  })
})
