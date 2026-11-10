import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  BubbleHarness,
  ButtonHarness,
  ToasterHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import BubbleReactions from 'docs-app/examples/bubble-reactions'

/** The audits, but for the destructive bubble's text (see bubble-variants-test.gts). */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_DESTRUCTIVE_TEXT = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="bubble"][data-variant="destructive"] > [data-slot="bubble-content"]']],
}

module('Example | bubble-reactions', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('reactions on either edge and end, and a quick action that runs', async function (assert) {
    // The app renders its Toaster once, in its application template; a test renders its own.
    await render(
      <template>
        <BubbleReactions />
        <Toaster />
      </template>,
    )
    const [tests, bold, passed, confirm] = BubbleHarness.findAll()

    assert.strictEqual(tests!.reactionsLabel, 'Reactions: thumbs up, surprised')
    assert.deepEqual([tests!.reactionsSide, tests!.reactionsAlign], ['bottom', 'start'])
    assert.strictEqual(bold!.reactionsLabel, 'Reactions: eyes, rocket, and 2 more')
    assert.deepEqual([bold!.reactionsSide, bold!.reactionsAlign], ['bottom', 'end'])
    assert.strictEqual(passed!.reactionsLabel, 'Reactions: party popper, clapping hands')
    assert.deepEqual([passed!.reactionsSide, passed!.reactionsAlign], ['top', 'start'])
    const top = passed!.reactions.getBoundingClientRect()
    const bubble = passed!.element.getBoundingClientRect()
    assert.ok(top.top < bubble.top, 'side="top": above the top edge')

    assert.strictEqual(confirm!.variant, 'destructive')
    const run = confirm!.find(ButtonHarness)
    assert.strictEqual(run.label, 'Yes, run it')
    await run.click()
    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.title, 'You clicked yes, running command...')
    assert.strictEqual(toast.type, 'success')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_DESTRUCTIVE_TEXT, { runOnly: ['color-contrast'] })
  })
})
