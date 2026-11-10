import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireResume from 'docs-app/examples/questionnaire-resume'

module('Example | questionnaire-resume', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('saved answers come back, and a reset restores them', async function (assert) {
    await render(
      <template>
        <QuestionnaireResume />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    assert.strictEqual(q.activeItem, 'verification', 'it resumes on the saved item')
    assert.deepEqual(q.checked(), ['tests', 'typecheck'])
    assert.deepEqual(q.checked('change'), ['incremental'])
    await q.choose('manual')
    await q.next()
    assert.strictEqual(q.input()!.value, 'Keep the existing public API stable.')
    await q.fillIn('Ship behind a flag.')

    await click(q.form.querySelector('button[type="reset"]')!)
    assert.strictEqual(new ToasterHarness().toast().title, 'Saved answers restored')
    assert.strictEqual(q.activeItem, 'verification')
    assert.deepEqual(q.checked(), ['tests', 'typecheck'])
    assert.strictEqual(q.input('notes')!.value, 'Keep the existing public API stable.')
    await a11yAudit()
  })
})
