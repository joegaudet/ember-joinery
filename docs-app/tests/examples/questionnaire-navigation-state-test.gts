import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireNavigationState from 'docs-app/examples/questionnaire-navigation-state'

module('Example | questionnaire-navigation-state', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('Next is disabled, and dimmed, until the item is answered', async function (assert) {
    await render(
      <template>
        <QuestionnaireNavigationState />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    const next = q.button('next')
    assert.dom(next).isDisabled().hasAttribute('data-status', 'unanswered')
    assert.dom(next).hasAttribute('data-variant', 'secondary')
    assert.strictEqual(getComputedStyle(next).opacity, '0.5', 'data-[status=unanswered]:opacity-50')
    await q.choose('tests')
    assert.dom(next).isNotDisabled().hasAttribute('data-status', 'answered')
    await q.next()
    assert.dom(q.button('submit')).isDisabled('the next item starts unanswered')
    await a11yAudit()
  })
})
