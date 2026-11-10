import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  EmptyHarness,
  InputGroupHarness,
  MessageHarness,
  MessageScrollerHarness,
} from '@ember-joinery/test-support'
import { chatTiming } from 'docs-app/examples/chat/scripted-chat'
import MessageScrollerStreaming from 'docs-app/examples/message-scroller-streaming'

/** The button with this accessible name. */
const button = (label: string) => ButtonHarness.findAll().find(button => button.label === label)!

/**
 * Whether the composer stacks its block-end addon below its 56px text (a column, as upstream's
 * does), rather than squeezing both into one row.
 */
function composerStacks(): boolean {
  const composer = new InputGroupHarness()
  const addon = composer.addon('block-end')
  return (
    getComputedStyle(composer.element).flexDirection === 'column' &&
    composer.element.offsetHeight >= 56 + addon.offsetHeight
  )
}

module('Example | message-scroller-streaming', function (hooks) {
  setupRenderingTest(hooks)
  // The reply streams in at once, with no delay between its words.
  hooks.beforeEach(() => void (chatTiming.scale = 0))
  hooks.afterEach(() => void (chatTiming.scale = 1))

  test('autoScroll follows the reply at the live edge, and leaves a reader who scrolled up alone', async function (assert) {
    await render(<template><MessageScrollerStreaming /></template>)
    assert.true(composerStacks(), 'the composer lays its buttons out below its text')
    assert.true(new EmptyHarness().exists)
    assert.true(button('Reset stream').isDisabled, 'nothing to reset yet')

    await button('Send').click()
    const chat = new MessageScrollerHarness()
    await chat.settle()
    assert.strictEqual(MessageHarness.findAll().length, 2)
    await button('Send').click()
    await chat.settle()
    await button('Send').click()
    await chat.settle()
    assert.true(chat.isAtEnd, 'it followed the streamed replies')
    assert.false(chat.isButtonActive(), 'no "jump to latest" while it follows')

    await chat.scrollBy(-300)
    assert.true(chat.isButtonActive(), 'scrolled up: the button appears')
    assert.true(chat.canScrollToEnd)
    await chat.clickButton()
    assert.true(chat.isAtEnd, 'the button brings them back')
    await button('Send').click()
    await chat.settle()
    assert.strictEqual(MessageHarness.findAll().length, 8)
    assert.true(button('Send').isDisabled, 'the script has run out')
    await button('Reset stream').click()
    assert.true(new EmptyHarness().exists)
    await a11yAudit()
  })
})
