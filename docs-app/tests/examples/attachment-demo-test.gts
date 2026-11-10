import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AttachmentGroupHarness, AttachmentHarness } from '@ember-joinery/test-support'
import AttachmentDemo from 'docs-app/examples/attachment-demo'

module('Example | attachment-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a row of images, an upload in progress and a finished file', async function (assert) {
    await render(<template><AttachmentDemo /></template>)
    const group = new AttachmentGroupHarness()
    assert.deepEqual(group.titles, ['workspace.png', 'desk-reference.jpg', 'office-reference.jpg'])
    assert.deepEqual(
      group.attachments.map(image => [image.orientation, image.mediaVariant, image.imageAlt]),
      [
        ['vertical', 'image', 'Workspace'],
        ['vertical', 'image', 'Desk'],
        ['vertical', 'image', 'Office'],
      ],
    )
    const [, , , upload, file] = AttachmentHarness.findAll()
    assert.strictEqual(upload!.state, 'uploading')
    assert.true(upload!.isBusy, 'its title shimmers')
    assert.strictEqual(upload!.description, 'Uploading · 64%')
    assert.dom('[role="status"]', upload!.media).exists('a spinner, announced')
    assert.deepEqual(upload!.actionLabels, ['Cancel upload'])
    assert.strictEqual(file!.state, 'done')
    assert.strictEqual(file!.title, 'message-renderer.tsx')
    assert.deepEqual(file!.actionLabels, ['Remove message-renderer.tsx'])
    await a11yAudit()
  })
})
