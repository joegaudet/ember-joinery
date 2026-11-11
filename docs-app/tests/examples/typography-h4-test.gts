import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyH4 from 'docs-app/examples/typography-h4'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-h4', function (hooks) {
  setupRenderingTest(hooks)

  test('a minor heading', async function (assert) {
    await render(<template><TypographyH4 /></template>)
    assert.dom('h4').hasText('People stopped telling jokes')
    const style = getComputedStyle(find('h4')!)
    assert.strictEqual(style.fontSize, '20px', 'text-xl')
    assert.strictEqual(style.fontWeight, '600', 'font-semibold')
    await a11yAudit()
  })
})
