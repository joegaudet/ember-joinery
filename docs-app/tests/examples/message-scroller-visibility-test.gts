import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { HoverCardHarness, MessageScrollerHarness } from '@ember-joinery/test-support'
import MessageScrollerVisibility from 'docs-app/examples/message-scroller-visibility'

/** Two positions within a pixel: the test container's scale rounds a scroll to its pixels. */
const near = (actual: number, expected: number) => Math.abs(actual - expected) <= 1

module('Example | message-scroller-visibility', function (hooks) {
  setupRenderingTest(hooks)

  test('the outline marks the turn the reader is in, and jumps to any other', async function (assert) {
    await render(<template><MessageScrollerVisibility /></template>)
    const chat = new MessageScrollerHarness()
    await chat.settle()
    const outline = new HoverCardHarness()
    const bars = () =>
      [...outline.trigger.querySelectorAll('[data-current]')].map(bar =>
        bar.getAttribute('data-current'),
      )
    assert.deepEqual(bars(), ['false', 'false', 'false', 'true'], 'it opens at the last turn')

    await outline.hover()
    assert.true(outline.isOpen)
    const entries = () => [...outline.content!.querySelectorAll('button')]
    assert.deepEqual(
      entries().map(entry => entry.textContent!.trim()),
      [
        'Review the incident handoff and tell me...',
        'What was the customer impact?',
        'What actions are open?',
        'Give me the follow-up checklist.',
      ],
    )
    assert.dom(entries()[3]).hasAttribute('aria-current', 'location')
    await click(entries()[1]!)
    await chat.settle()
    assert.true(
      near(chat.itemTop('vis-impact'), parseFloat(getComputedStyle(chat.content).paddingTop) + 12),
      'scrollMargin 12',
    )
    assert.deepEqual(bars(), ['false', 'true', 'false', 'false'])
    assert.dom(entries()[1]).hasAttribute('aria-current', 'location')
    await a11yAudit()
  })
})
