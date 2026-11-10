import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BubbleHarness } from '@ember-joinery/test-support'
import BubbleVariants from 'docs-app/examples/bubble-variants'

/**
 * The audits, but for the destructive bubble's text: upstream draws it `--destructive` on its
 * own 10% tint, under the 4.5:1 WCAG AA asks of its 14px text (the Bubble page's Accessibility
 * notes say so). One audit runs every other rule on it; the other checks the contrast of
 * everything else.
 */
const ALL_BUT_CONTRAST = {
  // The example, not the test's container: at its height the 384px container scrolls, with
  // nothing in it to focus, which a page that shows the example doesn't.
  include: [['#ember-testing']],
  rules: { 'color-contrast': { enabled: false } },
}
const BUT_THE_DESTRUCTIVE_TEXT = {
  include: [['#ember-testing']],
  exclude: [['[data-slot="bubble"][data-variant="destructive"] > [data-slot="bubble-content"]']],
}

module('Example | bubble-variants', function (hooks) {
  setupRenderingTest(hooks)

  test('the seven variants, alternating sides, and a ghost bubble that takes the row', async function (assert) {
    await render(<template><BubbleVariants /></template>)
    const bubbles = BubbleHarness.findAll()
    assert.deepEqual(
      bubbles.map(bubble => bubble.variant),
      ['default', 'secondary', 'muted', 'tinted', 'outline', 'destructive', 'ghost'],
    )
    assert.deepEqual(
      bubbles.map(bubble => bubble.align),
      ['start', 'end', 'start', 'end', 'start', 'end', 'start'],
    )
    assert.strictEqual(bubbles[0]!.text, 'This is the default primary bubble.')
    assert.strictEqual(bubbles[2]!.reactionsLabel, 'Reaction: thumbs up')
    assert.strictEqual(bubbles[5]!.reactionsLabel, 'Reaction: fire')

    const ghost = bubbles[6]!
    const container = ghost.element.parentElement!
    assert.strictEqual(
      ghost.element.offsetWidth,
      container.clientWidth,
      'a ghost bubble is as wide as the thread',
    )
    assert.ok(bubbles[0]!.element.offsetWidth < container.clientWidth * 0.8 + 1, 'up to 80%')
    const paragraphs = ghost.content.querySelectorAll('p')
    assert.strictEqual(paragraphs.length, 3, "the Markdown's three paragraphs")
    assert.strictEqual(
      getComputedStyle(paragraphs[0]!).marginBottom,
      '16px',
      'space-y-4 between them',
    )
    assert.strictEqual(ghost.content.querySelector('code')!.textContent, 'code')
    assert.strictEqual(getComputedStyle(ghost.content.querySelector('span')!).fontWeight, '600')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_DESTRUCTIVE_TEXT, { runOnly: ['color-contrast'] })
  })
})
