import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyMuted from 'docs-app/examples/typography-muted'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-muted', function (hooks) {
  setupRenderingTest(hooks)

  test('small, muted text', async function (assert) {
    await render(<template><TypographyMuted /></template>)
    assert.dom('p').hasText('Enter your email address.')
    const style = getComputedStyle(find('p')!)
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.notStrictEqual(style.color, getComputedStyle(getRootElement() as Element).color, 'muted')
    await a11yAudit()
  })
})
