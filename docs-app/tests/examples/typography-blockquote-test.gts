import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyBlockquote from 'docs-app/examples/typography-blockquote'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-blockquote', function (hooks) {
  setupRenderingTest(hooks)

  test('an italic quote with a rule on its start side', async function (assert) {
    await render(<template><TypographyBlockquote /></template>)
    assert.dom('blockquote').includesText('everyone enjoys a good joke')
    const style = getComputedStyle(find('blockquote')!)
    assert.strictEqual(style.fontStyle, 'italic')
    assert.strictEqual(style.borderLeftWidth, '2px', 'border-l-2')
    assert.strictEqual(style.paddingLeft, '24px', 'pl-6')
    assert.strictEqual(style.marginTop, '24px', 'mt-6')
    await a11yAudit()
  })
})
