import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness, MessageScrollerHarness } from '@ember-joinery/test-support'
import MessageScrollerScrollable from 'docs-app/examples/message-scroller-scrollable'

module('Example | message-scroller-scrollable', function (hooks) {
  setupRenderingTest(hooks)

  test('the footer says which ways the transcript can scroll', async function (assert) {
    await render(<template><MessageScrollerScrollable /></template>)
    const chat = new MessageScrollerHarness()
    await chat.settle()
    const footer = new CardHarness().footer
    assert.true(chat.isAtStart, 'it opens at the start')
    assert.dom(footer).hasText('You are at the top. You can only scroll down.')
    await chat.scrollTo(chat.maxScrollTop / 2)
    assert.dom(footer).hasText('You can scroll both ways.')
    await chat.pressKey('End')
    assert.dom(footer).hasText('You are at the bottom. You can only scroll up.')
    await a11yAudit()
  })
})
