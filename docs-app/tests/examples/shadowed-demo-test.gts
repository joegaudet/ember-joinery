import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ShadowedHarness } from '@ember-joinery/test-support'
import ShadowedDemo from 'docs-app/examples/shadowed-demo'

module('Example | shadowed-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the page’s style skews the paragraph outside, not the one in the shadow root', async function (assert) {
    await render(<template><ShadowedDemo /></template>)
    const outside = document.querySelector('p.shadow-demo')!
    const inside = new ShadowedHarness().query('p.shadow-demo')!

    assert.dom(outside).containsText('affected by the global styles')
    assert.notStrictEqual(getComputedStyle(outside).transform, 'none', 'skewed')
    assert.dom(inside).containsText('not affected')
    assert.strictEqual(getComputedStyle(inside).transform, 'none', 'not skewed')
    await a11yAudit()
  })
})
