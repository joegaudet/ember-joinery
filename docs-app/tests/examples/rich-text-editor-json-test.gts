import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, FieldHarness } from '@ember-joinery/test-support'
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'
import RichTextEditorJson from 'docs-app/examples/rich-text-editor-json'

module('Example | rich-text-editor-json', function (hooks) {
  setupRenderingTest(hooks)

  test('a trimmed toolbar, storing JSON, that needs some text', async function (assert) {
    await render(<template><RichTextEditorJson /></template>)
    const comment = new RichTextEditorHarness('comment')
    const field = new FieldHarness()
    const post = new ButtonHarness('post')

    assert.deepEqual(comment.tools, ['bold', 'italic', 'bullet-list'])
    assert.strictEqual(comment.placeholder, 'Leave a comment')
    await post.click()
    assert.strictEqual(field.error, 'Write a comment first')
    assert.true(comment.isInvalid)
    assert.strictEqual(comment.description, 'Write a comment first')

    await comment.typeText('Looks good')
    assert.strictEqual(field.error, '', 'the error goes as soon as there is text')
    assert.false(comment.isInvalid)
    assert.deepEqual(comment.json, {
      type: 'doc',
      content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Looks good' }] }],
    })

    await post.click()
    assert.true(comment.isEmpty, 'posting empties the box')
    await a11yAudit()
  })
})
