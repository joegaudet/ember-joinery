import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  ButtonHarness,
  MarkerHarness,
  MessageScrollerHarness,
  ToasterHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import MessageScrollerLoadHistory from 'docs-app/examples/message-scroller-load-history'

/** The button with this accessible name. */
const button = (label: string) => ButtonHarness.findAll().find(button => button.label === label)!

module('Example | message-scroller-load-history', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('earlier messages load above without moving the reader', async function (assert) {
    // The app renders its Toaster once, in its application template; a test renders its own.
    await render(
      <template>
        <MessageScrollerLoadHistory />
        <Toaster />
      </template>,
    )
    const chat = new MessageScrollerHarness()
    await chat.settle()
    assert.strictEqual(chat.messageIds.length, 5, 'the last five messages')
    assert.strictEqual(new MarkerHarness().text, 'End of Conversation')
    assert.true(chat.isAtEnd)

    const [first] = chat.visibleIds
    const before = chat.itemTop(first!)
    await button('Load History').click()
    await chat.settle()
    assert.strictEqual(chat.messageIds.length, 10, 'all ten')
    assert.true(Math.abs(chat.itemTop(first!) - before) <= 1, 'the reader stayed on their row')
    assert.strictEqual(new ToasterHarness().toast().title, 'History loaded')
    assert.true(button('History Loaded').isDisabled)

    await button('Reset loaded messages').click()
    await chat.settle()
    assert.strictEqual(chat.messageIds.length, 5)
    await a11yAudit()
  })
})
