import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  ButtonHarness,
  DialogHarness,
  QuestionnaireHarness,
  ToasterHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import QuestionnaireDialog from 'docs-app/examples/questionnaire-dialog'

module('Example | questionnaire-dialog', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a questionnaire in a dialog, named by the question it shows', async function (assert) {
    await render(
      <template>
        <QuestionnaireDialog />
        <Toaster />
      </template>,
    )
    const dialog = new DialogHarness()
    await new ButtonHarness().click()
    assert.true(dialog.isOpen)
    const q = new QuestionnaireHarness({ within: dialog })
    assert.strictEqual(dialog.label, 'Which files are in scope?')
    assert.strictEqual(q.progressText, 'Question 1 of 2')
    await q.choose('feature')
    await q.next()
    assert.strictEqual(
      dialog.label,
      'How much verification is needed?',
      'the next question names it',
    )
    assert.strictEqual(q.describedBy(), 'Choose the checks the agent should run before handoff.')
    await q.choose('package')
    await q.submit()
    assert.false(dialog.isOpen, 'sending the answer closes it')
    assert.strictEqual(
      new ToasterHarness().toast().description,
      'Scope: feature · Verification: package',
    )
    await a11yAudit()
  })
})
