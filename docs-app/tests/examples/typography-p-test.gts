import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyP from 'docs-app/examples/typography-p'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-p', function (hooks) {
  setupRenderingTest(hooks)

  test('a paragraph with a roomy line height', async function (assert) {
    await render(<template><TypographyP /></template>)
    assert.dom('p').includesText('repealed the joke tax.')
    assert.strictEqual(getComputedStyle(find('p')!).lineHeight, '28px', 'leading-7')
    await a11yAudit()
  })
})
