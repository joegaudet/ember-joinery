import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  AvatarHarness,
  BubbleGroupHarness,
  MarkerHarness,
  MessageHarness,
} from '@ember-joinery/test-support'
import MessageDemo from 'docs-app/examples/message-demo'

/**
 * The audits, but for the initials' contrast, which show where an avatar's image fails: upstream
 * draws them `--muted-foreground` on `--muted`, under the 4.5:1 WCAG AA asks of their text (the
 * Avatar page's Accessibility notes say so). One audit runs every other rule on them; the other
 * checks the contrast of everything else.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
}

module('Example | message-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a conversation: your messages at the end, theirs at the start, and a typing status', async function (assert) {
    await render(<template><MessageDemo /></template>)
    const messages = MessageHarness.findAll()
    assert.deepEqual(
      messages.map(message => message.align),
      ['end', 'start', 'end', 'start'],
    )
    assert.deepEqual(
      messages.map(message => message.bubbles.map(bubble => bubble.text)),
      [
        ['Deploying to prod real quick.'],
        ["It's 4:55 PM. On a Friday."],
        ["It's a one-line change."],
        ["It's always a one-line change 😭.", 'Alright, let me take a look.'],
      ],
    )
    assert.deepEqual(
      messages.map(message => message.bubbles[0]!.variant),
      ['default', 'muted', 'default', 'muted'],
    )
    for (const message of messages) {
      const avatar = message.find(AvatarHarness)
      assert.true(avatar.isLoaded || avatar.isError, 'its image, or its initials')
    }
    const mine = messages[0]!.find(AvatarHarness)
    assert.strictEqual(
      mine.label,
      mine.isLoaded ? '@me' : 'ME',
      'named by its alt, or its initials',
    )

    const [, , delivered, grouped] = messages
    assert.strictEqual(delivered!.footerText, 'Delivered')
    const group = grouped!.find(BubbleGroupHarness)
    assert.strictEqual(group.bubbles.length, 2, 'two bubbles in a group')
    assert.strictEqual(group.bubbles[1]!.reactionsLabel, 'Reactions: thumbs up')

    const typing = new MarkerHarness()
    assert.true(typing.isStatus, 'announced as it changes')
    assert.strictEqual(typing.text, 'Oliver is typing...')
    assert.dom(typing.content).hasClass('shimmer')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
