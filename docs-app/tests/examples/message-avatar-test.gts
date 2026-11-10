import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, MessageHarness } from '@ember-joinery/test-support'
import MessageAvatar from 'docs-app/examples/message-avatar'

/** The audits, but for the initials' contrast (see message-demo-test.gts). */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
}

module('Example | message-avatar', function (hooks) {
  setupRenderingTest(hooks)

  test('each message has an avatar at the bottom of its row, on its own side', async function (assert) {
    await render(<template><MessageAvatar /></template>)
    const [build, question, logs] = MessageHarness.findAll()

    assert.strictEqual(build!.align, 'start')
    assert.strictEqual(question!.align, 'end')
    assert.strictEqual(logs!.align, 'start')
    for (const message of [build!, question!, logs!]) {
      assert.true(message.hasAvatar)
      const avatar = message.find(AvatarHarness)
      assert.true(avatar.isLoaded || avatar.isError)
      assert.strictEqual(getComputedStyle(message.avatar).alignSelf, 'flex-end')
    }
    const row = question!.element.getBoundingClientRect()
    assert.strictEqual(
      Math.round(question!.avatar.getBoundingClientRect().right),
      Math.round(row.right),
      "your question's avatar is at the end",
    )
    assert.strictEqual(question!.bubbles[0]!.text, 'Can you share the exact error?')
    assert.deepEqual(
      logs!.bubbles.map(bubble => bubble.text),
      [
        "Here's the error from the logs",
        'Something went wrong with the build. The libraries are not installed correctly. Try running the build again.',
      ],
    )
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
