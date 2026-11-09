import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockTypeset from 'docs-app/examples/code-block-typeset'

module('Example | code-block-typeset', function (hooks) {
  setupRenderingTest(hooks)

  test('a block between the paragraphs of an article', async function (assert) {
    await render(<template><CodeBlockTypeset /></template>)
    const block = new CodeBlockHarness()
    const article = block.element.parentElement!
    assert.dom(article).hasClass('typeset')
    assert.dom('h3', article).hasText('Stream a response')
    assert.dom(block.element.previousElementSibling).hasTagName('p')
    assert.dom(block.element.nextElementSibling).hasTagName('p')
    assert.strictEqual(block.title, 'app/api/chat/route.ts')
    assert.true(block.isNumbered)
    assert.true(block.isHighlighted)
    await a11yAudit()
  })
})
