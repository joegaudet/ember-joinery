import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BubbleGroupHarness, BubbleHarness } from '@ember-joinery/test-support'
import BubbleDemo from 'docs-app/examples/bubble-demo'

module('Example | bubble-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a thread of bubbles on both sides, a group, and reactions read once by their label', async function (assert) {
    await render(<template><BubbleDemo /></template>)
    const bubbles = BubbleHarness.findAll()
    assert.deepEqual(
      bubbles.map(bubble => [bubble.align, bubble.variant]),
      [
        ['end', 'default'],
        ['start', 'muted'],
        ['start', 'muted'],
        ['end', 'default'],
        ['start', 'muted'],
      ],
    )
    assert.strictEqual(bubbles[0]!.text, "Hey there! what's up?")

    const group = new BubbleGroupHarness()
    assert.deepEqual(
      group.bubbles.map(bubble => bubble.text),
      [
        'Hey! Want to see chat bubbles?',
        'I can group messages, switch sides, and keep the whole thread easy to scan.',
      ],
    )
    const [, liked] = group.bubbles
    assert.strictEqual(liked!.reactionsLabel, 'Reaction: thumbs up')
    assert
      .dom(liked!.reactions)
      .hasAttribute('role', 'img', 'the emoji are read once, by the label')

    const last = bubbles[4]!
    assert.strictEqual(last.reactionsLabel, 'Reactions: thumbs up, fire, eyes, and 2 more')
    assert.dom(last.reactions).hasText('👍 🔥 👀 +2')
    await a11yAudit()
  })
})
