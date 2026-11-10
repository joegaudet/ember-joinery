import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { CardHarness, QuestionnaireHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireCard from 'docs-app/examples/questionnaire-card'

module('Example | questionnaire-card', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test("each question is the card's title, and names its item", async function (assert) {
    await render(
      <template>
        <QuestionnaireCard />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    const card = new CardHarness()
    assert.true(card.exists)
    const title = q.item().querySelector('[data-slot="questionnaire-title"]')!
    assert.dom(title).hasClass('jn-card-title').hasClass('jn-questionnaire-title')
    assert.dom(q.item()).hasAttribute('aria-labelledby', title.id)
    assert.strictEqual(q.title(), 'What should the agent work on?')
    assert.strictEqual(q.describedBy(), 'Choose the task that should be handled next.')
    assert.strictEqual(q.shortcut('docs'), '3', 'number shortcuts')
    assert.strictEqual(q.progressText, 'Question 1 of 2')
    await q.focusChoice('fix')
    await q.press('2')
    assert.true(q.isChecked('refactor'))
    await q.next()
    assert.strictEqual(q.title(), 'What should the final handoff include?')
    await a11yAudit()
  })
})
