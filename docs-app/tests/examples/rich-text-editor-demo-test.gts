import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'
import RichTextEditorDemo from 'docs-app/examples/rich-text-editor-demo'

module('Example | rich-text-editor-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('formats with the toolbar and stores HTML', async function (assert) {
    await render(<template><RichTextEditorDemo /></template>)
    const title = new InputHarness()
    const body = new RichTextEditorHarness('body')

    assert.strictEqual(title.value, 'Release notes')
    assert.strictEqual(body.label, 'Body', 'its FieldLabel names it')
    assert.strictEqual(
      body.description,
      'Markdown shortcuts work too: ## for a heading, - for a list',
    )
    assert.strictEqual(new FieldHarness({ index: 1 }).label, 'Body')
    await body.moveCursor('start')
    assert.strictEqual(body.blockType, 'Heading 2')

    await body.setContent('<p>Shipping today</p>')
    await body.selectAll()
    await body.press('bold')
    assert.true(body.isActive('bold'))
    assert.strictEqual(body.html, '<p><strong>Shipping today</strong></p>')

    await body.press('undo')
    assert.strictEqual(body.html, '<p>Shipping today</p>')
    await a11yAudit()
  })
})
