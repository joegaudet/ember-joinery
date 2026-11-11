import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, MessageScrollerHarness } from '@ember-joinery/test-support'
import MessageScrollerCommands from 'docs-app/examples/message-scroller-commands'

/** Two positions within a pixel: the test container's scale rounds a scroll to its pixels. */
const near = (actual: number, expected: number) => Math.abs(actual - expected) <= 1

module('Example | message-scroller-commands', function (hooks) {
  setupRenderingTest(hooks)

  test('a menu outside the transcript jumps to any turn', async function (assert) {
    await render(<template><MessageScrollerCommands /></template>)
    const chat = new MessageScrollerHarness()
    await chat.settle()
    assert.true(chat.isAtEnd, 'it opens at the end')

    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.deepEqual(menu.labels, ['Conversations'])
    assert.deepEqual(menu.items, [
      "We're seeing activation dip after works...",
      'What should I compare before we change ...',
      'Can you turn that into an experiment?',
      "What's the risk if we delay the invite ...",
    ])
    await menu.select('What should I compare before we change ...')
    await chat.settle()
    const padding = parseFloat(getComputedStyle(chat.content).paddingTop)
    assert.true(near(chat.itemTop('command-compare'), padding))
    assert.true(chat.isButtonActive(), 'more below')
    await a11yAudit()
  })
})
