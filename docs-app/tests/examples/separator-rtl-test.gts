import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { SeparatorHarness } from '@ember-joinery/test-support'
import SeparatorRtl from 'docs-app/examples/separator-rtl'

module('Example | separator-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the line still spans the column, and the text starts on the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><SeparatorRtl /></DirectionProvider>
      </template>,
    )
    const separator = new SeparatorHarness()
    const column = separator.element.parentElement!
    assert.strictEqual(getComputedStyle(separator.element).width, getComputedStyle(column).width)
    assert.strictEqual(getComputedStyle(column).direction, 'rtl')
    assert.ok(getRootElement().textContent!.includes('الأساس لنظام التصميم الخاص بك'))
    await a11yAudit()
  })
})
