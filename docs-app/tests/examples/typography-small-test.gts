import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographySmall from 'docs-app/examples/typography-small'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-small', function (hooks) {
  setupRenderingTest(hooks)

  test('small, medium-weight text on one line height', async function (assert) {
    await render(<template><TypographySmall /></template>)
    assert.dom('small').hasText('Email address')
    const style = getComputedStyle(find('small')!)
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.strictEqual(style.lineHeight, '14px', 'leading-none')
    assert.strictEqual(style.fontWeight, '500', 'font-medium')
    await a11yAudit()
  })
})
