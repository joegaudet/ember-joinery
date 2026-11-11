import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, findAll, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import TypographyRtl from 'docs-app/examples/typography-rtl'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the logical classes put the rules and indents on the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><TypographyRtl /></DirectionProvider>
      </template>,
    )
    assert.dom('h1').hasText('فرض الضرائب على الضحك: سجلات ضريبة النكتة')
    assert.strictEqual(findAll('h3').length, 3)

    const quote = getComputedStyle(find('blockquote')!)
    assert.strictEqual(quote.borderRightWidth, '2px', 'border-s-2, on the right')
    assert.strictEqual(quote.borderLeftWidth, '0px')
    assert.strictEqual(quote.paddingRight, '24px', 'ps-6, on the right')
    assert.strictEqual(getComputedStyle(find('ul')!).marginRight, '24px', 'ms-6, on the right')

    const cell = find('td')!
    const row = cell.parentElement!.getBoundingClientRect()
    assert.ok(cell.getBoundingClientRect().right === row.right, 'the first column is on the right')
    assert.strictEqual(find('a')!.textContent, 'خطة عبقرية')
    await a11yAudit()
  })
})
