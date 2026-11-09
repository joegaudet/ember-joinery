import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AccordionHarness } from '@ember-joinery/test-support'
import AccordionMultiple from 'docs-app/examples/accordion-multiple'

module('Example | accordion-multiple', function (hooks) {
  setupRenderingTest(hooks)

  test('several items open at once', async function (assert) {
    await render(<template><AccordionMultiple /></template>)
    const settings = new AccordionHarness()
    assert.deepEqual(settings.titles, [
      'Notification Settings',
      'Privacy & Security',
      'Billing & Subscription',
    ])
    assert.deepEqual(settings.openValues, ['notifications'])

    await settings.open('billing')
    assert.deepEqual(settings.openValues, ['notifications', 'billing'], 'both stay open')
    await settings.close('notifications')
    assert.deepEqual(settings.openValues, ['billing'])
    await a11yAudit()
  })
})
