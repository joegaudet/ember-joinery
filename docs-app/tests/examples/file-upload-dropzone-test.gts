import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'
import FileUploadDropzone from 'docs-app/examples/file-upload-dropzone'

module('Example | file-upload-dropzone', function (hooks) {
  setupRenderingTest(hooks)

  test('a zone of its own, and previews of the photos', async function (assert) {
    await render(<template><FileUploadDropzone /></template>)
    const photos = new FileUploadHarness('photos')

    assert.strictEqual(photos.text, 'Drag photos here PNG, JPG or SVG Browse photos')
    assert.deepEqual(photos.files, ['dawn.svg', 'dusk.svg'])
    assert.true(
      photos.items.every(item => item.hasPreview),
      'each photo previews itself',
    )
    assert.dom(photos.element).containsText('Chosen: 2')

    const photo = new File(['<svg/>'], 'noon.svg', { type: 'image/svg+xml' })
    await photos.drag(photo)
    assert.strictEqual(photos.text, 'Drop your photos PNG, JPG or SVG Browse photos')
    await photos.drop(photo)
    assert.deepEqual(photos.files, ['dawn.svg', 'dusk.svg', 'noon.svg'])
    assert.dom(photos.element).containsText('Chosen: 3')
    await a11yAudit()
  })
})
