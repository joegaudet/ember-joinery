import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { inIframe, notInIframe } from '@ember-joinery/primitives/iframe'
import { ReadoutHarness } from 'test-app/tests/fixtures/primitives/readout'

module('Integration | primitives | iframe', function (hooks) {
  setupRenderingTest(hooks)

  test('the tests run in the top-level window', async function (assert) {
    assert.false(inIframe())
    assert.true(notInIframe())
    await render(
      <template>
        <p data-test-jn="readout" data-test-jn-name="in">
          {{if (inIframe) "in a frame" "not in a frame"}}
        </p>
        <p data-test-jn="readout" data-test-jn-name="not">
          {{if (notInIframe) "the top window" "a frame"}}
        </p>
      </template>,
    )
    assert.strictEqual(new ReadoutHarness('in').text, 'not in a frame')
    assert.strictEqual(new ReadoutHarness('not').text, 'the top window')
    await a11yAudit()
  })

  test('in a frame, it says so', async function (assert) {
    const frame = document.createElement('iframe')
    frame.title = 'A frame'
    document.body.append(frame)
    try {
      // The frame's window runs the same check against its own self and top.
      const framed = frame.contentWindow! as unknown as Window & typeof globalThis
      const check = new framed.Function(`return (${inIframe.toString()})()`) as () => boolean
      assert.true(check(), 'inside the frame, inIframe() is true')
    } finally {
      frame.remove()
    }
    await a11yAudit()
  })
})
