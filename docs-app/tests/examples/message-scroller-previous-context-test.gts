import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, MessageScrollerHarness, SliderHarness } from '@ember-joinery/test-support'
import { chatTiming } from 'docs-app/examples/chat/scripted-chat'
import MessageScrollerPreviousContext from 'docs-app/examples/message-scroller-previous-context'

/** Two positions within a pixel: the test container's scale rounds a scroll to its pixels. */
const near = (actual: number, expected: number) => Math.abs(actual - expected) <= 1

/** The button with this accessible name. */
const button = (label: string) => ButtonHarness.findAll().find(button => button.label === label)!

module('Example | message-scroller-previous-context', function (hooks) {
  setupRenderingTest(hooks)
  // The reply streams in at once, with no delay between its words.
  hooks.beforeEach(() => void (chatTiming.scale = 0))
  hooks.afterEach(() => void (chatTiming.scale = 1))

  test('the slider sets how much of the previous reply peeks above a new turn', async function (assert) {
    await render(<template><MessageScrollerPreviousContext /></template>)
    const chat = new MessageScrollerHarness()
    await chat.settle()
    assert.strictEqual(chat.messageIds.length, 2, 'it opens on the first exchange')
    const peek = new SliderHarness()
    assert.deepEqual(peek.value, [64])
    assert.deepEqual([peek.min, peek.max], [64, 128])

    const padding = parseFloat(getComputedStyle(chat.content).paddingTop)
    await button('Send').click()
    await chat.settle()
    const [, second] = chat.anchorIds
    // scrollMargin 24, plus the 64px peek.
    assert.true(near(chat.itemTop(second!), padding + 24 + 64))

    await peek.press('End')
    assert.deepEqual(peek.value, [128])
    assert.dom(peek.element.parentElement!).includesText('128px')
    await button('Send').click()
    await chat.settle()
    const third = chat.anchorIds[2]!
    assert.true(near(chat.itemTop(third), padding + 24 + 128))

    await button('Reset context example').click()
    await chat.settle()
    assert.strictEqual(chat.messageIds.length, 2)
    assert.deepEqual(new SliderHarness().value, [64], 'the peek goes back too')
    await a11yAudit()
  })
})
