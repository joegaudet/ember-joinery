import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'
import FileUploadRtl from 'docs-app/examples/file-upload-rtl'

module('Example | file-upload-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><FileUploadRtl /></div>
      </template>,
    )
    const documents = new FileUploadHarness('documents')

    assert.strictEqual(
      documents.text,
      'اختر الملفات أو اسحبها وأفلتها هنا صور أو ملفات PDF، حتى 5 ميغابايت',
    )
    const report = documents.file('التقرير-السنوي.pdf')
    assert.strictEqual(report.removeButton.label, 'إزالة التقرير-السنوي.pdf')
    assert.true(
      report.media.getBoundingClientRect().left >
        report.removeButton.element.getBoundingClientRect().left,
      'the media on the right, the remove button on the left',
    )

    await documents.drop(new File(['…'], 'ملاحظات.txt', { type: 'text/plain' }))
    assert.strictEqual(documents.rejected, 'نوع غير مقبول: ملاحظات.txt')
    await a11yAudit()
  })
})
