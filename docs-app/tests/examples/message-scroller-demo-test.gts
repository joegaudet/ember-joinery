import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  DropdownMenuHarness,
  EmptyHarness,
  InputGroupHarness,
  MessageHarness,
  MessageScrollerHarness,
} from '@ember-joinery/test-support'
import { chatTiming } from 'docs-app/examples/chat/scripted-chat'
import MessageScrollerDemo from 'docs-app/examples/message-scroller-demo'

/** Two positions within a pixel: the test container's scale rounds a scroll to its pixels. */
const near = (actual: number, expected: number) => Math.abs(actual - expected) <= 1

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

/**
 * The composer's menu. Its trigger, the "Add files" button, sits inside the InputGroup (the
 * menu goes around the whole group, so the group keeps its block-end addon as a child), which
 * makes the button the group's in the component tree: this page object points the menu's
 * harness at it.
 */
class ComposerMenu extends DropdownMenuHarness {
  override get trigger(): HTMLElement {
    return button('Add files').element
  }
}

module('Example | message-scroller-demo', function (hooks) {
  setupRenderingTest(hooks)
  // The reply streams in at once, with no delay between its words.
  hooks.beforeEach(() => void (chatTiming.scale = 0))
  hooks.afterEach(() => void (chatTiming.scale = 1))

  test('a new chat: send streams a scripted reply, and the next turn settles near the top', async function (assert) {
    await render(<template><MessageScrollerDemo /></template>)
    assert.true(composerStacks(), 'the composer lays its buttons out below its text')
    assert.true(new EmptyHarness().exists, 'it opens empty')
    assert.dom('[data-status]').includesText("I'm building a chat for our app")

    await button('Send').click()
    const chat = new MessageScrollerHarness()
    await chat.settle()
    const [question, answer] = MessageHarness.findAll()
    assert.strictEqual(question!.align, 'end')
    assert.strictEqual(answer!.align, 'start')
    assert.true(
      answer!.bubbles[0]!.text.startsWith("That's the classic streaming scroll problem."),
      'the whole reply streamed in',
    )
    assert.deepEqual(chat.anchorIds, [chat.messageIds[0]], "the user's turn is the anchor")
    assert.dom(chat.content).hasAttribute('aria-busy', 'false', 'done streaming')

    await button('Send').click()
    await chat.settle()
    const turn = chat.anchorIds[1]!
    const padding = parseFloat(getComputedStyle(chat.content).paddingTop)
    assert.true(
      near(chat.itemTop(turn), padding + 64),
      'the new turn, with the previous reply peeking above it',
    )

    const menu = new ComposerMenu()
    await menu.open()
    assert.deepEqual(menu.items, [
      'Add Photos & Files',
      'Create Image',
      'Deep Research',
      'Web Search',
    ])
    await menu.close()

    await button('Reset conversation').click()
    assert.true(new EmptyHarness().exists, 'Reset clears the conversation')
    await a11yAudit()
  })
})
