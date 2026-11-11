import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'
import RichTextEditorRtl from 'docs-app/examples/rich-text-editor-rtl'

module('Example | rich-text-editor-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic: the toolbar runs from the right and its arrows flip', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><RichTextEditorRtl /></DirectionProvider>
      </template>,
    )
    const notes = new RichTextEditorHarness('notes')
    assert.strictEqual(notes.toolbarLabel, 'التنسيق')
    assert.strictEqual(notes.toolLabel('bold'), 'غامق')
    assert.strictEqual(notes.label, 'الملاحظات')
    assert.strictEqual(getComputedStyle(notes.content).direction, 'rtl')

    const bold = notes.tool('bold').getBoundingClientRect()
    const italic = notes.tool('italic').getBoundingClientRect()
    assert.true(italic.right <= bold.left, 'italic comes after bold, to its left')

    await notes.focusTool('bold')
    await notes.pressKey('ArrowLeft')
    assert.strictEqual(notes.focusedTool, 'italic', 'the left arrow moves on')

    await notes.moveCursor('start')
    assert.strictEqual(notes.blockType, 'عنوان 2')
    await a11yAudit()
  })
})
