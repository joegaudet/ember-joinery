import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, dragFilesAway, dragFilesOver, dropFiles } from '@ember-joinery/test-support'
import FileDropDocumentHeadless from 'docs-app/examples/file-drop-document-headless'

/** The example's own paragraph, which shows the drag. */
class PageDrop extends Harness {
  static override component = 'page-drop'

  get isDragging(): boolean {
    return this.element.hasAttribute('data-dragging')
  }

  get text(): string {
    return (this.element.textContent ?? '').replace(/\s+/g, ' ').trim()
  }
}

const clip = new File(['clip'], 'clip.webm', { type: 'video/webm' })

module('Example | file-drop-document-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a drag over the page shows on the block; a drop anywhere takes the file', async function (assert) {
    await render(<template><FileDropDocumentHeadless /></template>)
    const page = new PageDrop()

    assert.false(page.isDragging)
    assert.strictEqual(page.text, 'Dropped: nothing yet')

    assert.true(await dragFilesOver(document.body, [clip]), 'the page allows the drop')
    assert.true(page.isDragging, 'page.isDragging')
    assert.strictEqual(page.text, 'Drop the file anywhere on the page')
    assert.notStrictEqual(getComputedStyle(page.element).borderTopStyle, 'none')
    await dragFilesAway(document.body, [clip])
    assert.false(page.isDragging, 'dragged away again')

    assert.true(await dropFiles(document.body, [clip]), 'the file doesn’t open in the tab')
    assert.false(page.isDragging)
    assert.strictEqual(page.text, 'Dropped: clip.webm')
    await a11yAudit()
  })
})
