import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupTextareaExample from 'docs-app/examples/input-group-textarea'

module('Example | input-group-textarea', function (hooks) {
  setupRenderingTest(hooks)

  test('a code editor: a file header above the textarea and a status bar below', async function (assert) {
    await render(<template><InputGroupTextareaExample /></template>)
    const editor = new InputGroupHarness()
    assert.dom(editor.control).hasTagName('textarea').hasAttribute('id', 'textarea-code-32')
    assert.deepEqual(editor.aligns, ['block-end', 'block-start'])
    const header = editor.addon('block-start').getBoundingClientRect()
    const footer = editor.addon('block-end').getBoundingClientRect()
    const box = editor.control.getBoundingClientRect()
    assert.ok(header.bottom <= box.top && box.bottom <= footer.top, 'header, textarea, footer')
    assert.strictEqual(getComputedStyle(editor.control).minHeight, '200px', 'min-h-[200px]')
    assert.deepEqual(editor.texts, ['Line 1, Column 1', 'script.js'])

    const [run, refresh, copy] = ButtonHarness.findAll()
    assert.strictEqual(run!.label, 'Run')
    assert.strictEqual(run!.variant, 'default')
    assert.strictEqual(refresh!.label, 'Refresh')
    assert.strictEqual(copy!.label, 'Copy')
    assert.strictEqual(getComputedStyle(copy!.element).width, '24px', 'icon-xs')

    await editor.fillIn("console.log('hi')")
    assert.strictEqual(editor.value, "console.log('hi')")
    await a11yAudit()
  })
})
