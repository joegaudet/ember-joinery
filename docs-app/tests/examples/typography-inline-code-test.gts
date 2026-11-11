import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyInlineCode from 'docs-app/examples/typography-inline-code'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-inline-code', function (hooks) {
  setupRenderingTest(hooks)

  test('code in a monospace font, on a muted chip', async function (assert) {
    await render(<template><TypographyInlineCode /></template>)
    assert.dom('code').hasText('@radix-ui/react-alert-dialog')
    const style = getComputedStyle(find('code')!)
    assert.ok(/mono/i.test(style.fontFamily), 'font-mono')
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.strictEqual(style.fontWeight, '600', 'font-semibold')
    assert.strictEqual(style.borderTopLeftRadius, '4px', 'rounded')
    assert.strictEqual(style.paddingLeft, '4.8px', 'px-[0.3rem]')
    assert.notStrictEqual(style.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-muted')
    await a11yAudit()
  })
})
