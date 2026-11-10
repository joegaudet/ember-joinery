import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, MessageHarness } from '@ember-joinery/test-support'
import MessageActions from 'docs-app/examples/message-actions'

module('Example | message-actions', function (hooks) {
  setupRenderingTest(hooks)

  test('named icon buttons in the footers: copy and feedback, and a retry for a failed send', async function (assert) {
    await render(<template><MessageActions /></template>)
    const [reply, mine] = MessageHarness.findAll()

    const actions = reply!.findAll(ButtonHarness)
    assert.deepEqual(
      actions.map(button => button.label),
      ['Copy', 'Like', 'Dislike'],
      'each icon-only button has a name',
    )
    assert.true(actions.every(button => button.variant === 'ghost' && button.size === 'icon'))
    for (const button of actions) {
      assert.true(reply!.footer.contains(button.element), 'in the footer')
    }

    assert.strictEqual(mine!.align, 'end')
    const retry = mine!.find(ButtonHarness)
    assert.strictEqual(retry.label, 'Retry')
    assert.strictEqual(retry.size, 'icon-xs')
    assert.dom(mine!.footer).includesText('Failed to send')
    assert.strictEqual(getComputedStyle(mine!.footer).columnGap, '8px', 'gap-2')
    assert.strictEqual(getComputedStyle(mine!.footer).justifyContent, 'flex-end')
    await a11yAudit()
  })
})
