import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'
import FileUploadDisabled from 'docs-app/examples/file-upload-disabled'

module('Example | file-upload-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('takes no files and removes none', async function (assert) {
    await render(<template><FileUploadDisabled /></template>)
    const contract = new FileUploadHarness('contract')

    assert.true(contract.isDisabled)
    assert.strictEqual(contract.text, 'Uploads are closed The contract has been signed')
    assert.false(contract.file('signed-contract.pdf').canRemove)
    await contract.drop(new File(['…'], 'draft.pdf', { type: 'application/pdf' }))
    assert.deepEqual(contract.files, ['signed-contract.pdf'])
    await a11yAudit()
  })
})
