import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MarkerHarness } from '@ember-joinery/test-support'
import MarkerVariants from 'docs-app/examples/marker-variants'

module('Example | marker-variants', function (hooks) {
  setupRenderingTest(hooks)

  test('an inline marker, a separator with a line each side, and a bordered row', async function (assert) {
    await render(<template><MarkerVariants /></template>)
    const [inline, separator, border] = MarkerHarness.findAll()
    assert.strictEqual(inline!.variant, 'default')
    assert.strictEqual(inline!.text, 'A default marker for inline notes.')

    assert.strictEqual(separator!.variant, 'separator')
    assert.strictEqual(getComputedStyle(separator!.element, '::before').height, '1px')
    assert.strictEqual(getComputedStyle(separator!.element, '::after').height, '1px')
    assert.strictEqual(getComputedStyle(separator!.content).textAlign, 'center')
    assert.strictEqual(separator!.role, null, 'its label is read as text, without a role')

    assert.strictEqual(border!.variant, 'border')
    assert.strictEqual(getComputedStyle(border!.element).borderBottomWidth, '1px')
    await a11yAudit()
  })
})
