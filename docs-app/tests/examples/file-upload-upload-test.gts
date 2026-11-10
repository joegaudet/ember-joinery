import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'
import FileUploadUpload from 'docs-app/examples/file-upload-upload'

module('Example | file-upload-upload', function (hooks) {
  setupRenderingTest(hooks)

  test('uploads as files are chosen, and keeps the results', async function (assert) {
    await render(<template><FileUploadUpload /></template>)
    const attachments = new FileUploadHarness('attachments')

    const notes = new File(['minutes'], 'notes.txt', { type: 'text/plain' })
    const huge = new File([new Uint8Array(2_000_000)], 'huge.mov', { type: 'video/quicktime' })
    await attachments.select(notes, huge)
    assert.deepEqual(attachments.uploading, ['notes.txt', 'huge.mov'])
    assert.true(attachments.isUploading)
    assert.strictEqual(attachments.file('notes.txt').progressBar.label, 'Uploading notes.txt')
    await a11yAudit()

    await attachments.waitForUploads()
    assert.deepEqual(attachments.files, ['notes.txt'], 'listed as what the upload resolved to')
    assert.deepEqual(attachments.failed, ['huge.mov'])
    assert.strictEqual(
      attachments.file('huge.mov').details,
      'Too large for this demo (1 MB at most)',
    )

    await attachments.remove('huge.mov')
    assert.deepEqual(attachments.failed, [])
    assert.deepEqual(attachments.files, ['notes.txt'])
    await a11yAudit()
  })
})
