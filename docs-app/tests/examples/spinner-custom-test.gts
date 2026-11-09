import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerCustom from 'docs-app/examples/spinner-custom'

module('Example | spinner-custom', function (hooks) {
  setupRenderingTest(hooks)

  test("a spinner that turns lucide's loader instead", async function (assert) {
    await render(<template><SpinnerCustom /></template>)
    const spinner = new SpinnerHarness()
    assert.strictEqual(spinner.role, 'status')
    assert.strictEqual(spinner.label, 'Loading')
    // lucide's loader is eight strokes; the default loader-circle is one arc.
    assert.dom('path', spinner.element).exists({ count: 8 })
    assert.ok(getComputedStyle(spinner.element).animationName.includes('spin'))
    assert.strictEqual(getComputedStyle(spinner.element).width, '16px')
    await a11yAudit()
  })
})
