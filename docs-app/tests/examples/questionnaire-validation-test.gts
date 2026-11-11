import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  CardHarness,
  QuestionnaireHarness,
  ToasterHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import QuestionnaireValidation from 'docs-app/examples/questionnaire-validation'

module('Example | questionnaire-validation', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('your own validation sends the questionnaire back to the invalid item', async function (assert) {
    await render(
      <template>
        <QuestionnaireValidation />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.true(new CardHarness().exists, 'in a card')
    assert.dom(q.progress).hasText('1 / 2', 'a progress of its own')
    await q.choose('summary')
    await q.next()
    await q.choose('public')
    await q.submit()
    assert.strictEqual(q.activeItem, 'detail', 'back to the item the schema rejected')
    assert.true(q.isInvalid())
    assert.strictEqual(q.error(), 'Public answers need enough context. Choose a complete answer.')
    assert.true(q.isItemFocused())
    await q.choose('complete')
    assert.false(q.isInvalid(), 'choosing again clears the error')
    await q.next()
    await q.submit()
    assert.strictEqual(
      new ToasterHarness().toast().description,
      'Detail: complete · Audience: public',
    )
    await a11yAudit()
  })
})
