import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireFreeform from 'docs-app/examples/questionnaire-freeform'

module('Example | questionnaire-freeform', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a written answer instead of a fixed one', async function (assert) {
    await render(
      <template>
        <QuestionnaireFreeform />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.dom(q.input()).hasAttribute('aria-label', 'Another refactoring approach')
    await q.choose('module')
    await q.fillIn('Pair on the riskiest module first')
    assert.deepEqual(q.checked(), [], 'the written answer takes over')
    await q.submit()
    assert.strictEqual(
      new ToasterHarness().toast().description,
      'Approach: Pair on the riskiest module first',
    )
    await a11yAudit()
  })
})
