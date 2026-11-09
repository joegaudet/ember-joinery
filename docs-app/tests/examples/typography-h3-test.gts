import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyH3 from 'docs-app/examples/typography-h3'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-h3', function (hooks) {
  setupRenderingTest(hooks)

  test('a sub-heading', async function (assert) {
    await render(<template><TypographyH3 /></template>)
    assert.dom('h3').hasText('The Joke Tax')
    const style = getComputedStyle(find('h3')!)
    assert.strictEqual(style.fontSize, '24px', 'text-2xl')
    assert.strictEqual(style.fontWeight, '600', 'font-semibold')
    await a11yAudit()
  })
})
