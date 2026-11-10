import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AttachmentHarness, MessageHarness } from '@ember-joinery/test-support'
import MessageAttachment from 'docs-app/examples/message-attachment'

module('Example | message-attachment', function (hooks) {
  setupRenderingTest(hooks)

  test('an image sent with a message, and a file sent back', async function (assert) {
    await render(<template><MessageAttachment /></template>)
    const [sent, reply, thanks] = MessageHarness.findAll()
    assert.strictEqual(sent!.align, 'end')
    const image = sent!.find(AttachmentHarness)
    assert.strictEqual(image.orientation, 'vertical')
    assert.strictEqual(image.imageAlt, 'Workspace')
    assert.strictEqual(
      sent!.bubbles[0]!.text,
      "Here's the image. Can you add it to the PDF? Use it for the cover page.",
    )

    assert.strictEqual(reply!.align, 'start')
    const file = reply!.find(AttachmentHarness)
    assert.strictEqual(file.title, 'sales-dashboard.pdf')
    assert.strictEqual(file.description, 'PDF · 2.4 MB')
    const download = file.action('Download')
    assert.strictEqual(download.variant, 'secondary')
    assert.strictEqual(download.size, 'icon-sm')
    assert.dom(download.element).hasAttribute('title', 'Download').hasAttribute('type', 'button')
    assert.strictEqual(thanks!.bubbles[0]!.text, 'Thanks. Looks good.')
    await a11yAudit()
  })
})
