import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BubbleGroupHarness, BubbleHarness } from '@ember-joinery/test-support'
import BubbleGroupDemo from 'docs-app/examples/bubble-group-demo'

module('Example | bubble-group-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('three bubbles from you in a group, each aligned to the end', async function (assert) {
    await render(<template><BubbleGroupDemo /></template>)
    const group = new BubbleGroupHarness()
    assert.deepEqual(
      group.bubbles.map(bubble => bubble.text),
      ['You tell me!', 'It worked yesterday. You broke it!', 'Find the bug and fix it.'],
    )
    assert.true(
      group.bubbles.every(bubble => bubble.align === 'end'),
      'align is on each bubble',
    )

    const last = group.bubbles[2]!
    assert.strictEqual(last.reactionsLabel, 'Reactions: eyes')
    assert.strictEqual(last.reactionsAlign, 'start')
    assert.strictEqual(BubbleHarness.findAll().length, 5, 'and two of theirs around it')
    await a11yAudit()
  })
})
