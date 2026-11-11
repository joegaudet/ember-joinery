import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'
import FileUploadDemo from 'docs-app/examples/file-upload-demo'

module('Example | file-upload-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('choose, drop and remove files', async function (assert) {
    await render(<template><FileUploadDemo /></template>)
    const resume = new FileUploadHarness('resume')
    const samples = new FileUploadHarness('samples')

    assert.deepEqual(resume.files, ['ada-lovelace-cv.pdf'])
    assert.strictEqual(resume.file('ada-lovelace-cv.pdf').details, 'PDF · 184.3 kB')
    assert.false(resume.isMultiple)
    assert.strictEqual(resume.accept, '.pdf')
    await resume.select(new File(['%PDF'], 'cv-2026.pdf', { type: 'application/pdf' }))
    assert.deepEqual(resume.files, ['cv-2026.pdf'], 'one file: a new choice replaces it')

    assert.true(samples.file('analytical-engine.svg').hasPreview, 'a picture previews itself')
    assert.false(samples.file('note-g.pdf').hasPreview)
    const sketch = new File(['<svg/>'], 'sketch.svg', { type: 'image/svg+xml' })
    const notes = new File(['…'], 'notes.txt', { type: 'text/plain' })
    await samples.drop(sketch, notes)
    assert.deepEqual(samples.files, ['analytical-engine.svg', 'note-g.pdf', 'sketch.svg'])
    assert.strictEqual(samples.rejected, 'Not an accepted type: notes.txt')

    await samples.remove('note-g.pdf')
    assert.deepEqual(samples.files, ['analytical-engine.svg', 'sketch.svg'])
    await a11yAudit()
  })
})
