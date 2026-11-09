import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockShowMore from 'docs-app/examples/code-block-show-more'

module('Example | code-block-show-more', function (hooks) {
  setupRenderingTest(hooks)

  test('capped until Show more expands it', async function (assert) {
    await render(<template><CodeBlockShowMore /></template>)
    const block = new CodeBlockHarness()
    const toggle = block.find(ButtonHarness, { index: 1 })

    assert.strictEqual(toggle.text, 'Show more')
    assert.dom(toggle.element).hasAttribute('aria-expanded', 'false')
    assert.dom(toggle.element).hasAttribute('aria-controls', block.content.id)
    assert.ok(block.footer!.contains(toggle.element), 'in the footer')
    assert.strictEqual(getComputedStyle(block.content).maxHeight, '256px', 'max-h-64')
    assert.strictEqual(getComputedStyle(block.content).overflowY, 'hidden')

    await toggle.click()
    assert.strictEqual(toggle.text, 'Show less')
    assert.dom(toggle.element).hasAttribute('aria-expanded', 'true')
    assert.strictEqual(getComputedStyle(block.content).maxHeight, 'none', 'all of it shows')
    assert.strictEqual(block.lines.length, 34)
    await a11yAudit()
  })
})
