import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireConditional from 'docs-app/examples/questionnaire-conditional'

module('Example | questionnaire-conditional', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('the environment question applies to cloud runs only', async function (assert) {
    await render(
      <template>
        <QuestionnaireConditional />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.true(q.isChecked('local'))
    assert.strictEqual(q.progressText, 'Question 1 of 2')
    await q.next()
    assert.strictEqual(q.activeItem, 'approval', 'a local run passes the environment')
    await q.previous()
    await q.choose('cloud')
    assert.strictEqual(q.progressText, 'Question 1 of 3')
    await q.next()
    assert.strictEqual(q.activeItem, 'environment')
    await q.choose('staging')
    await q.next()
    await q.choose('commands')
    await q.submit()
    assert.strictEqual(
      new ToasterHarness().toast().description,
      'Runtime: cloud · Environment: staging · Approval: commands',
    )
    await a11yAudit()
  })
})
