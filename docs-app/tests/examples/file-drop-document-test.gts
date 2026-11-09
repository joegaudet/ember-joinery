import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DocumentFileDropHarness } from '@ember-joinery/test-support'
import FileDropDocument from 'docs-app/examples/file-drop-document'

const clip = new File(['clip'], 'clip.webm', { type: 'video/webm' })

module('Example | file-drop-document', function (hooks) {
  setupRenderingTest(hooks)

  test('dragging over the page shows the overlay; a drop anywhere takes the file', async function (assert) {
    await render(<template><FileDropDocument /></template>)
    const page = new DocumentFileDropHarness()

    assert.false(page.isShown)
    assert.true(await page.drag([clip]), 'the page allows the drop')
    assert.true(page.isShown)
    assert.strictEqual(page.text, 'Drop the file anywhere on the page')
    await a11yAudit()

    assert.true(await page.drop([clip]), 'and keeps the file from opening in the tab')
    assert.false(page.isShown)
    assert.dom(getRootElement() as Element).containsText('Dropped: clip.webm')
    await a11yAudit()
  })
})
