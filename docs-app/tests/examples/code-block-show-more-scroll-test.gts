import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockShowMoreScroll from 'docs-app/examples/code-block-show-more-scroll'

module('Example | code-block-show-more-scroll', function (hooks) {
  setupRenderingTest(hooks)

  test('expanded, the cap rises and the content scrolls', async function (assert) {
    await render(<template><CodeBlockShowMoreScroll /></template>)
    const block = new CodeBlockHarness()
    const toggle = block.find(ButtonHarness, { index: 1 })
    assert.strictEqual(getComputedStyle(block.content).maxHeight, '256px')

    await toggle.click()
    assert.dom(toggle.element).hasAttribute('aria-expanded', 'true')
    assert.strictEqual(getComputedStyle(block.content).maxHeight, '384px', 'max-h-96')
    assert.strictEqual(getComputedStyle(block.content).overflowY, 'auto')
    assert.ok(block.content.scrollHeight > block.content.clientHeight, 'and scrolls')
    await a11yAudit()
  })
})
