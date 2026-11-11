import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, MessageGroupHarness } from '@ember-joinery/test-support'
import MessageGroup from 'docs-app/examples/message-group'

/** The audits, but for the initials' contrast (see message-demo-test.gts). */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
}

module('Example | message-group', function (hooks) {
  setupRenderingTest(hooks)

  test('two messages from one sender, the first with an empty avatar slot to line up', async function (assert) {
    await render(<template><MessageGroup /></template>)
    const group = new MessageGroupHarness()
    const [first, last] = group.messages
    assert.strictEqual(group.messages.length, 2)

    assert.true(first!.hasAvatar, 'a slot')
    assert.dom(first!.avatar).hasNoText('with nothing in it')
    assert.false(first!.find(AvatarHarness).exists)
    assert.true(last!.find(AvatarHarness).exists)
    assert.strictEqual(
      Math.round(first!.content.getBoundingClientRect().left),
      Math.round(last!.content.getBoundingClientRect().left),
      'both bubbles start in line',
    )
    assert.strictEqual(getComputedStyle(group.element).rowGap, '8px', 'closer than the rows')
    assert.deepEqual(
      group.messages.map(message => message.bubbles[0]!.text),
      [
        'I checked the registry addresses.',
        'The component and example JSON now live under the UI registry.',
      ],
    )
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
