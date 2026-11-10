/* global Keyframe -- a DOM type, which ESLint's browser globals don't list */
import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  EmptyHarness,
  MessageScrollerHarness,
  SelectHarness,
} from '@ember-joinery/test-support'
import { chatTiming } from 'docs-app/examples/chat/scripted-chat'
import MessageScrollerAnimation from 'docs-app/examples/message-scroller-animation'

/** The button with this accessible name. */
const button = (label: string) => ButtonHarness.findAll().find(button => button.label === label)!

module('Example | message-scroller-animation', function (hooks) {
  setupRenderingTest(hooks)
  // The reply streams in at once, with no delay between its words.
  hooks.beforeEach(() => void (chatTiming.scale = 0))
  hooks.afterEach(() => void (chatTiming.scale = 1))

  test("a user's row plays the picked entrance; the reply streams in below without one", async function (assert) {
    const played: Keyframe[][] = []
    const animate = HTMLElement.prototype.animate
    HTMLElement.prototype.animate = function (this: HTMLElement, keyframes, options) {
      played.push(keyframes as Keyframe[])
      return animate.call(this, keyframes, options)
    }
    try {
      await render(<template><MessageScrollerAnimation /></template>)
      assert.true(new EmptyHarness().exists)
      const preset = new SelectHarness()
      assert.strictEqual(preset.valueText, 'Fade')

      await button('Send Message').click()
      const chat = new MessageScrollerHarness()
      await chat.settle()
      assert.strictEqual(chat.messageIds.length, 2)
      assert.deepEqual(played, [[{ opacity: 0 }, { opacity: 1 }]], 'one entrance, the fade')

      await preset.select('pop')
      assert.strictEqual(preset.valueText, 'Pop')
      await button('Send Message').click()
      await chat.settle()
      assert.strictEqual(played.length, 2)
      assert.strictEqual(played[1]![0]!.transform, 'translateY(6px) scale(0.94)', 'then the pop')
    } finally {
      HTMLElement.prototype.animate = animate
    }
    await a11yAudit()
  })
})
