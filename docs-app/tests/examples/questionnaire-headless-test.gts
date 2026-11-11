import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { QuestionnaireHarness } from '@ember-joinery/test-support'
import QuestionnaireHeadless from 'docs-app/examples/questionnaire-headless'

module('Example | questionnaire-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the headless parts, styled by the page, with the same behaviour', async function (assert) {
    await render(<template><QuestionnaireHeadless /></template>)
    const q = new QuestionnaireHarness()
    assert.dom(q.form).doesNotHaveAttribute('data-slot', 'no styled slots')
    assert.strictEqual(q.progressText, 'Question 1 of 2')
    assert.strictEqual(q.shortcut('questions'), 'B')
    await q.next()
    assert.strictEqual(q.error(), 'Choose an answer to continue.')
    await q.focusChoice('delegation')
    await q.press('b')
    assert.true(q.isChecked('questions'))
    await q.next()
    assert.strictEqual(q.activeItem, 'detail')
    assert.true(q.canSkip)
    await a11yAudit()
  })
})
