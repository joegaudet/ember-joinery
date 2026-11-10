import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, MessageHarness, TraceCollapsibleHarness } from '@ember-joinery/test-support'
import TraceThinking from 'docs-app/examples/trace-thinking'
import { chatTiming } from 'docs-app/examples/trace/scripted-chat'

module('Example | trace-thinking', function (hooks) {
  setupRenderingTest(hooks)

  hooks.beforeEach(() => {
    chatTiming.scale = 0
  })
  hooks.afterEach(() => {
    chatTiming.scale = 1
  })

  test('a reasoning part streams in as a row, then the reply', async function (assert) {
    await render(<template><TraceThinking /></template>)
    assert.strictEqual(MessageHarness.findAll().length, 0, 'it starts empty')
    const send = new ButtonHarness()
    assert.strictEqual(send.label, 'Send message')
    await send.click()

    const [question, reply] = MessageHarness.findAll()
    assert.strictEqual(question!.text, 'Why is the checkout deploy so slow?')
    const thought = reply!.find(TraceCollapsibleHarness)
    assert.strictEqual(thought.line.title, 'Thought')
    assert.false(thought.line.isRunning)
    await thought.open()
    assert.true(thought.text.startsWith('The build log shows install and compile finish'))
    assert.true(reply!.text.includes('Image optimization is the bottleneck.'))

    assert.strictEqual(send.label, 'Reset')
    await send.click()
    assert.strictEqual(MessageHarness.findAll().length, 0)
    await a11yAudit()
  })
})
