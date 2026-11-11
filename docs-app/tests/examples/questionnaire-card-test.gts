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

  test('two cards on a page name their items by ids of their own', async function (assert) {
    await render(
      <template>
        <QuestionnaireCard />
        <QuestionnaireCard />
        <Toaster />
      </template>,
    )
    const cards = QuestionnaireHarness.findAll()
    assert.strictEqual(cards.length, 2)
    const ids = cards.flatMap(q =>
      q.itemNames.map(name => q.item(name).getAttribute('aria-labelledby')),
    )
    assert.strictEqual(new Set(ids).size, 4, 'four items, four ids')
    for (const q of cards) {
      for (const name of q.itemNames) {
        const item = q.item(name)
        const title = item.querySelector('[data-slot="questionnaire-title"]')!
        assert.strictEqual(item.getAttribute('aria-labelledby'), title.id, `${name}: its own title`)
      }
    }
    await a11yAudit()
  })
})
