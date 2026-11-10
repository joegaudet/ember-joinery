import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireSkip from 'docs-app/examples/questionnaire-skip'

module('Example | questionnaire-skip', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('an optional item skipped on purpose', async function (assert) {
    await render(
      <template>
        <QuestionnaireSkip />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.false(q.canSkip, 'a required item has no Skip')
    await q.choose('fix')
    await q.next()
    assert.true(q.canSkip)
    await q.next()
    assert.strictEqual(q.activeItem, 'constraints', 'an unanswered optional item stays…')
    await q.skip()
    assert.strictEqual(q.status('constraints'), 'skipped', '…until it is skipped')
    await q.choose('both')
    await q.submit()
    assert.strictEqual(
      new ToasterHarness().toast().description,
      'Task: fix · Constraints: Skipped · Review: both',
    )
    await a11yAudit()
  })
})
