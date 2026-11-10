import { module, test } from 'qunit'
import { settled, waitUntil } from '@ember/test-helpers'
import { destroy } from '@ember/destroyable'
import { ChatSession, createChat } from 'docs-app/examples/trace/scripted-chat'

/** Whether the reply's thinking has streamed in whole: the stream is in its long sleep. */
function thought(session: ChatSession): boolean {
  const part = session.messages[1]?.parts[0]
  return part?.type === 'reasoning' && part.state === 'done'
}

/**
 * The Trace examples' scripted chat streams its reply on timers. A session given an owner ends
 * with it, so an example torn down mid-stream (the reader leaves the page) writes nothing more
 * and lets the test waiter go at once.
 */
module('Unit | trace scripted chat', function () {
  const chat = createChat()
    .user('Why is the build slow?')
    .assistant(({ writer }) => {
      writer.reasoning('Reading the build log, line by line.')
      writer.sleep(60_000)
      writer.text('Image optimization is the bottleneck.')
    })

  test('stop() ends a reply before it begins', async function (assert) {
    const session = new ChatSession(chat, { messages: [], delayMs: 0 })
    session.send(chat.next(session.messages)!)
    assert.strictEqual(session.status, 'submitted')
    session.stop()
    await settled()
    assert.deepEqual(
      session.messages.map(message => message.role),
      ['user'],
      'stopped before the reply began',
    )
  })

  test('once its owner is destroyed, a streaming reply stops and writes nothing more', async function (assert) {
    const owner = {}
    const session = new ChatSession(chat, { messages: [], delayMs: 1, owner })
    session.send(chat.next(session.messages)!)
    // The thinking streams in, then the stream sleeps for a minute.
    await waitUntil(() => thought(session))
    assert.strictEqual(session.status, 'streaming', 'streaming when the owner goes')
    const messages = session.messages

    destroy(owner)
    await settled()
    assert.strictEqual(session.messages, messages, 'nothing written after the owner is gone')
    assert.strictEqual(
      session.messages[1]!.parts.some(part => part.type === 'text'),
      false,
      'the reply stopped where it was',
    )
  })

  test('setMessages stops a reply that is streaming', async function (assert) {
    const session = new ChatSession(chat, { messages: [], delayMs: 1 })
    session.send(chat.next(session.messages)!)
    await waitUntil(() => thought(session))
    session.setMessages([])
    await settled()
    assert.deepEqual(session.messages, [])
    assert.strictEqual(session.status, 'ready')
  })
})
