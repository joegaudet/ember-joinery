import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockWrap from 'docs-app/examples/code-block-wrap'

module('Example | code-block-wrap', function (hooks) {
  setupRenderingTest(hooks)

  test('the same error, scrolling and wrapped', async function (assert) {
    await render(<template><CodeBlockWrap /></template>)
    const [scrolls, wraps] = CodeBlockHarness.findAll()
    assert.false(scrolls!.isWrapped)
    assert.ok(scrolls!.content.scrollWidth > scrolls!.content.clientWidth, 'the first scrolls')
    assert.true(wraps!.isWrapped)
    assert.strictEqual(wraps!.content.scrollWidth, wraps!.content.clientWidth, 'the second wraps')
    assert.ok(wraps!.content.clientHeight > scrolls!.content.clientHeight)
    assert.strictEqual(scrolls!.code, wraps!.code)
    await a11yAudit()
  })
})
