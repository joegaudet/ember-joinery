import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MessageHarness } from '@ember-joinery/test-support'
import MessageHeaderFooter from 'docs-app/examples/message-header-footer'

module('Example | message-header-footer', function (hooks) {
  setupRenderingTest(hooks)

  test("a sender's name above one message, and a read status below the other", async function (assert) {
    await render(<template><MessageHeaderFooter /></template>)
    const [olivia, mine] = MessageHarness.findAll()

    assert.strictEqual(olivia!.headerText, 'Olivia')
    assert.strictEqual(olivia!.footerText, '')
    assert.strictEqual(olivia!.bubbles[0]!.text, 'I already checked the logs.')

    assert.strictEqual(mine!.align, 'end')
    assert.strictEqual(mine!.headerText, '')
    assert.strictEqual(mine!.footerText, 'Read Yesterday')
    assert.strictEqual(
      getComputedStyle(mine!.footer).justifyContent,
      'flex-end',
      'the footer follows the message to the end',
    )
    assert.strictEqual(getComputedStyle(mine!.footer).fontWeight, '500')
    assert.strictEqual(
      getComputedStyle(mine!.footer.querySelector('span')!).fontWeight,
      '400',
      'font-normal on the time',
    )
    await a11yAudit()
  })
})
