import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MessageScrollerHarness } from '@ember-joinery/test-support'
import { chatTiming } from 'docs-app/examples/chat/scripted-chat'
import MessageScrollerHeadless from 'docs-app/examples/message-scroller-headless'

module('Example | message-scroller-headless', function (hooks) {
  setupRenderingTest(hooks)
  // The reply streams in at once, with no delay between its words.
  hooks.beforeEach(() => void (chatTiming.scale = 0))
  hooks.afterEach(() => void (chatTiming.scale = 1))

  test('the headless parts, with markup and styles of your own', async function (assert) {
    await render(<template><MessageScrollerHeadless /></template>)
    const chat = new MessageScrollerHarness()
    await chat.settle()
    assert.dom(chat.element).doesNotHaveAttribute('data-slot', 'no styled frame')
    assert.strictEqual(chat.messageIds.length, 2)
    assert.dom(chat.button()).hasText('Jump to latest').hasAttribute('inert')
    await click('button:not([data-test-jn-part])')
    await chat.settle()
    assert.strictEqual(chat.messageIds.length, 4, 'a turn and its streamed reply')
    assert.dom('button:not([data-test-jn-part])').isDisabled('the script has run out')
    await a11yAudit()
  })
})
