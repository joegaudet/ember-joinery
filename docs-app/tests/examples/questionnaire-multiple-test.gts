import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireMultiple from 'docs-app/examples/questionnaire-multiple'

module('Example | questionnaire-multiple', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('checkboxes: every source that applies', async function (assert) {
    await render(
      <template>
        <QuestionnaireMultiple />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.true(q.isMultiple())
    assert.strictEqual(q.choiceInput('source').type, 'checkbox')
    await q.choose('source')
    await q.choose('history')
    await q.submit()
    assert.strictEqual(new ToasterHarness().toast().description, 'Context: source, history')
    await a11yAudit()
  })
})
