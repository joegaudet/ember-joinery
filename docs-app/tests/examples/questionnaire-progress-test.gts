import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireProgress from 'docs-app/examples/questionnaire-progress'

module('Example | questionnaire-progress', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a progress of segments, one filled per item done', async function (assert) {
    await render(
      <template>
        <QuestionnaireProgress />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    const segments = () => [...q.progress.querySelectorAll('span.rounded-full')]
    const filled = () => segments().filter(segment => segment.classList.contains('bg-primary'))
    assert.strictEqual(segments().length, 4)
    assert.strictEqual(filled().length, 1)
    assert.dom(q.progress).hasText('Checkpoint 1 of 4')
    assert.strictEqual(q.progressText, 'Question 1 of 4', 'the progressbar still reads as one')
    await q.choose('medium')
    await q.next()
    assert.strictEqual(filled().length, 2)
    assert.dom(q.progress).hasText('Checkpoint 2 of 4')
    await a11yAudit()
  })
})
