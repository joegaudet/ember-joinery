import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyLarge from 'docs-app/examples/typography-large'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-large', function (hooks) {
  setupRenderingTest(hooks)

  test('large, semibold text', async function (assert) {
    await render(<template><TypographyLarge /></template>)
    assert.dom('div').hasText('Are you absolutely sure?')
    const style = getComputedStyle(find('div')!)
    assert.strictEqual(style.fontSize, '18px', 'text-lg')
    assert.strictEqual(style.fontWeight, '600', 'font-semibold')
    await a11yAudit()
  })
})
