import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyH2 from 'docs-app/examples/typography-h2'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-h2', function (hooks) {
  setupRenderingTest(hooks)

  test('a section heading with a rule under it', async function (assert) {
    await render(<template><TypographyH2 /></template>)
    assert.dom('h2').hasText('The People of the Kingdom')
    const style = getComputedStyle(find('h2')!)
    assert.strictEqual(style.fontSize, '30px', 'text-3xl')
    assert.strictEqual(style.fontWeight, '600', 'font-semibold')
    assert.strictEqual(style.borderBottomWidth, '1px', 'border-b')
    assert.strictEqual(style.paddingBottom, '8px', 'pb-2')
    assert.strictEqual(style.marginTop, '0px', 'first:mt-0')
    await a11yAudit()
  })
})
