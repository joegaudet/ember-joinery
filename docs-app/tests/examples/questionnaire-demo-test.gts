import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireDemo from 'docs-app/examples/questionnaire-demo'

module('Example | questionnaire-demo', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('three questions: one answer or your own, several or none, then one', async function (assert) {
    // The app renders its Toaster once, in its application template; a test renders its own.
    await render(
      <template>
        <QuestionnaireDemo />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.strictEqual(q.progressText, 'Question 1 of 3')
    assert.strictEqual(q.title(), 'What should the agent build next?')
    assert.deepEqual(
      q.choices().map(value => q.shortcut(value)),
      ['A', 'B', 'C'],
      'letter shortcuts',
    )
    await q.next()
    assert.strictEqual(q.error(), 'Choose an answer to continue.', 'it must be answered')
    await q.press('b')
    assert.true(q.isChecked('approvals'), 'B picks the second')
    await q.next()

    assert.strictEqual(q.activeItem, 'signals')
    assert.true(q.canSkip, 'an optional item can be skipped')
    await q.choose('decisions')
    await q.choose('risks')
    await q.next()

    assert.strictEqual(q.activeItem, 'timing')
    await q.choose('now')
    assert.strictEqual(q.button('submit').textContent?.trim(), 'Save plan')
    await q.submit()
    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.title, 'Agent plan saved')
    assert.strictEqual(
      toast.description,
      'Direction: approvals · Progress signals: decisions, risks · Timing: now',
    )
    await a11yAudit()
  })
})
