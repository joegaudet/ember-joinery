import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  MarkerHarness,
  MessageHarness,
  MessageScrollerHarness,
} from '@ember-joinery/test-support'
import MessageScrollerGroupChat from 'docs-app/examples/message-scroller-group-chat'

/** Two positions within a pixel: the test container's scale rounds a scroll to its pixels. */
const near = (actual: number, expected: number) => Math.abs(actual - expected) <= 1

/** The button with this accessible name. */
const button = (label: string) => ButtonHarness.findAll().find(button => button.label === label)!

module('Example | message-scroller-group-chat', function (hooks) {
  setupRenderingTest(hooks)

  test('a join marker anchors the next turn, then the reply comes in below it', async function (assert) {
    await render(<template><MessageScrollerGroupChat /></template>)
    const chat = new MessageScrollerHarness()
    await chat.settle()
    assert.deepEqual(chat.messageIds, ['group-1', 'group-2', 'group-3'])
    const messages = MessageHarness.findAll()
    assert.deepEqual(
      messages.map(message => [message.align, message.headerText]),
      [
        ['end', ''],
        ['start', 'Mary (Agent)'],
        ['end', ''],
      ],
      "others' messages carry their name",
    )
    assert.deepEqual(
      messages.map(message => message.bubbles[0]!.variant),
      ['muted', 'ghost', 'muted'],
    )

    await button('Add Rocky').click()
    await chat.settle()
    const marker = new MarkerHarness()
    assert.strictEqual(marker.text, 'Rocky has joined the chat')
    const row = chat.items.at(-1)!
    assert
      .dom(row)
      .hasAttribute('data-scroll-anchor', 'true')
      .doesNotHaveAttribute('data-message-id')
    const padding = parseFloat(getComputedStyle(chat.content).paddingTop)
    const top =
      (row.getBoundingClientRect().top - chat.viewport.getBoundingClientRect().top) /
      (chat.viewport.getBoundingClientRect().height / chat.viewport.offsetHeight)
    assert.true(near(top, padding + 64), 'the marker settles near the top')

    await button('Send Message as Rocky').click()
    await chat.settle()
    const rocky = MessageHarness.findAll().at(-1)!
    assert.strictEqual(rocky.headerText, 'Rocky')
    assert.strictEqual(rocky.bubbles[0]!.variant, 'tinted')
    assert.true(button('Send Message as Rocky').isDisabled)

    await button('Reset conversation').click()
    await chat.settle()
    assert.deepEqual(chat.messageIds, ['group-1', 'group-2', 'group-3'])
    await a11yAudit()
  })
})
