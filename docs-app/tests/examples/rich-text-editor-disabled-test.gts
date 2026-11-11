import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'
import RichTextEditorDisabled from 'docs-app/examples/rich-text-editor-disabled'

module('Example | rich-text-editor-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('read-only shows the document without a toolbar; disabled dims it all', async function (assert) {
    await render(<template><RichTextEditorDisabled /></template>)
    const notice = new RichTextEditorHarness('notice')
    assert.true(notice.isReadonly)
    assert.false(notice.isEditable)
    assert.strictEqual(notice.toolbar, null)
    assert.strictEqual(notice.text, 'The office is closed on Friday. Deliveries resume on Monday.')

    const draft = new RichTextEditorHarness('draft')
    assert.true(draft.isDisabled)
    assert.false(draft.isEditable)
    assert.true(draft.tools.every(tool => draft.isToolDisabled(tool)))
    assert.strictEqual(draft.label, 'Draft')
    await a11yAudit()
  })
})
