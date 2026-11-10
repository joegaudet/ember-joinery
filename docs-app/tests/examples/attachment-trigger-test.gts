import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AttachmentHarness, DialogHarness } from '@ember-joinery/test-support'
import AttachmentTriggerDemo from 'docs-app/examples/attachment-trigger'

module('Example | attachment-trigger', function (hooks) {
  setupRenderingTest(hooks)

  test('the card opens a preview dialog, and its actions stay clickable above it', async function (assert) {
    await render(<template><AttachmentTriggerDemo /></template>)
    const attachment = new AttachmentHarness()
    const dialog = new DialogHarness()
    assert.strictEqual(attachment.triggerLabel, 'Preview research-summary.pdf')
    assert.deepEqual(attachment.actionLabels, ['Copy link', 'Remove research-summary.pdf'])

    await attachment.action('Copy link').click()
    assert.false(dialog.isOpen, 'an action does not open the preview')

    await attachment.open()
    assert.true(dialog.isOpen)
    assert.strictEqual(dialog.label, 'research-summary.pdf')
    await a11yAudit()
    await dialog.pressEscape()
    assert.false(dialog.isOpen)
    assert.dom(attachment.trigger).isFocused('focus is back on the card')
    await a11yAudit()
  })
})
