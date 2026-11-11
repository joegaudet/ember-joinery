import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireControlled from 'docs-app/examples/questionnaire-controlled'

module('Example | questionnaire-controlled', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('the host shows the item it holds', async function (assert) {
    await render(
      <template>
        <QuestionnaireControlled />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    const status = document.querySelector('[role="status"]')!
    assert.dom(status).hasText('Current checkpoint: Change scope')
    await q.choose('tests')
    await q.next()
    assert.strictEqual(q.activeItem, 'checks')
    assert.dom(status).hasText('Current checkpoint: Verification', '@onItemChange')
    await q.previous()
    assert.dom(status).hasText('Current checkpoint: Change scope')
    await a11yAudit()
  })
})
