import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { QuestionnaireHarness, setupToaster } from '@ember-joinery/test-support'
import QuestionnaireAnimated from 'docs-app/examples/questionnaire-animated'

module('Example | questionnaire-animated', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('the active item animates in; progress and actions stay put', async function (assert) {
    await render(
      <template>
        <QuestionnaireAnimated />
        <Toaster />
      </template>,
    )
    const q = new QuestionnaireHarness()
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    assert.strictEqual(
      getComputedStyle(q.item()).animationName === 'enter',
      !reduce,
      'data-active:animate-in, unless motion is reduced',
    )
    await q.choose('debug')
    await q.next()
    assert.strictEqual(q.activeItem, 'review')
    assert.strictEqual(getComputedStyle(q.progress).animationName, 'none')
    await a11yAudit()
  })
})
