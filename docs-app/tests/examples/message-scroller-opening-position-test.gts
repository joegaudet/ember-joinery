import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MessageScrollerHarness, TabsHarness } from '@ember-joinery/test-support'
import MessageScrollerOpeningPosition from 'docs-app/examples/message-scroller-opening-position'

/** Two positions within a pixel: the test container's scale rounds a scroll to its pixels. */
const near = (actual: number, expected: number) => Math.abs(actual - expected) <= 1

module('Example | message-scroller-opening-position', function (hooks) {
  setupRenderingTest(hooks)

  test('a saved transcript opens at the start, the end, or the last anchored turn', async function (assert) {
    await render(<template><MessageScrollerOpeningPosition /></template>)
    const chat = new MessageScrollerHarness()
    await chat.settle()
    const tabs = new TabsHarness()
    assert.deepEqual(tabs.tabValues, ['start', 'end', 'last-anchor'])
    assert.strictEqual(tabs.selected, 'last-anchor')
    assert.true(chat.isItemVisible('open-3'), "it opens on the user's last message")
    assert.false(chat.isAtStart)

    await tabs.select('start')
    await chat.settle()
    assert.true(chat.isAtStart)

    await tabs.select('end')
    await chat.settle()
    assert.true(chat.isAtEnd)

    // Every row has rendered now: a row far out of view is only estimated until it has
    // (content-visibility: auto), so the first jump can land a few pixels out.
    await tabs.select('last-anchor')
    await chat.settle()
    const padding = parseFloat(getComputedStyle(chat.content).paddingTop)
    assert.true(near(chat.itemTop('open-3'), padding + 64), "the user's last message, 64px down")
    await a11yAudit()
  })
})
