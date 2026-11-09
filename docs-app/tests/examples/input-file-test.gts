import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputFile from 'docs-app/examples/input-file'

module('Example | input-file', function (hooks) {
  setupRenderingTest(hooks)

  test('a file input for a picture', async function (assert) {
    await render(<template><InputFile /></template>)
    const field = new FieldHarness()
    const picture = field.find(InputHarness)

    assert.strictEqual(picture.type, 'file')
    assert.strictEqual(picture.label, 'Picture')
    assert.strictEqual(field.description, 'Select a picture to upload.')
    await picture.chooseFiles([new File(['…'], 'me.png', { type: 'image/png' })])
    assert.deepEqual(picture.fileNames, ['me.png'])
    await a11yAudit()
  })
})
