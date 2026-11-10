import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { BubbleGroupHarness, ToasterHarness, setupToaster, tab } from '@ember-joinery/test-support'
import BubbleLinkButton from 'docs-app/examples/bubble-link-button'

module('Example | bubble-link-button', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('suggested replies are buttons: in the tab order, and each one answers', async function (assert) {
    // The app renders its Toaster once, in its application template; a test renders its own.
    await render(
      <template>
        <BubbleLinkButton />
        <Toaster />
      </template>,
    )
    const replies = new BubbleGroupHarness().bubbles
    assert.deepEqual(
      replies.map(reply => reply.text),
      [
        'I forgot my password',
        'I need help with my subscription',
        'Something else. Talk to a human.',
      ],
    )
    assert.true(replies.every(reply => reply.isInteractive && reply.variant === 'tinted'))
    assert.dom(replies[0]!.content).hasTagName('button')

    await tab()
    assert.true(replies[0]!.isFocused, 'Tab reaches the first reply')
    await tab()
    assert.true(replies[1]!.isFocused)

    await replies[0]!.click()
    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.toast().title, 'You clicked forgot password')
    await a11yAudit()
  })
})
