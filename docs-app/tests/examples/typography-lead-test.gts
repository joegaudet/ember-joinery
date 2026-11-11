import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyLead from 'docs-app/examples/typography-lead'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-lead', function (hooks) {
  setupRenderingTest(hooks)

  test('a large, muted introduction', async function (assert) {
    await render(<template><TypographyLead /></template>)
    assert.dom('p').includesText('A modal dialog that interrupts the user')
    const style = getComputedStyle(find('p')!)
    assert.strictEqual(style.fontSize, '20px', 'text-xl')
    assert.notStrictEqual(style.color, getComputedStyle(getRootElement() as Element).color, 'muted')
    await a11yAudit()
  })
})
