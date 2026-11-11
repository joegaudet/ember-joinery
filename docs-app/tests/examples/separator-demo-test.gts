import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SeparatorHarness } from '@ember-joinery/test-support'
import SeparatorDemo from 'docs-app/examples/separator-demo'

module('Example | separator-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a line between a heading and its text, which assistive technology skips', async function (assert) {
    await render(<template><SeparatorDemo /></template>)
    const separator = new SeparatorHarness()
    assert.strictEqual(separator.orientation, 'horizontal')
    assert.true(separator.isDecorative)
    const line = getComputedStyle(separator.element)
    assert.strictEqual(line.height, '1px')
    assert.strictEqual(
      line.width,
      getComputedStyle(separator.element.parentElement!).width,
      'the full width of the column',
    )
    assert.ok(getRootElement().textContent!.includes('The Foundation for your Design System'))
    await a11yAudit()
  })
})
