import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  NativeSelectHarness,
  QuestionnaireHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import QuestionnaireShortcuts from 'docs-app/examples/questionnaire-shortcuts'

module('Example | questionnaire-shortcuts', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('letters, numbers or no shortcuts', async function (assert) {
    await render(
      <template>
        <QuestionnaireShortcuts />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.strictEqual(q.shortcut('patch'), 'C')
    const style = new NativeSelectHarness()
    await style.select('numbers')
    assert.strictEqual(q.shortcut('patch'), '3')
    await q.focusChoice('inspect')
    await q.press('2')
    assert.true(q.isChecked('tests'))
    await style.select('none')
    assert.strictEqual(q.shortcut('patch'), null)
    await a11yAudit()
  })
})
