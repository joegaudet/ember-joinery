import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyH1 from 'docs-app/examples/typography-h1'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-h1', function (hooks) {
  setupRenderingTest(hooks)

  test('a centred, extra-bold page title', async function (assert) {
    await render(<template><TypographyH1 /></template>)
    assert.dom('h1').hasText('Taxing Laughter: The Joke Tax Chronicles')
    const style = getComputedStyle(find('h1')!)
    assert.strictEqual(style.fontSize, '36px', 'text-4xl')
    assert.strictEqual(style.fontWeight, '800', 'font-extrabold')
    assert.strictEqual(style.textAlign, 'center')
    assert.strictEqual(style.letterSpacing, '-0.9px', 'tracking-tight')
    assert.strictEqual(style.textWrapStyle, 'balance', 'text-balance')
    assert.strictEqual(style.scrollMarginTop, '80px', 'scroll-m-20')
    await a11yAudit()
  })
})
