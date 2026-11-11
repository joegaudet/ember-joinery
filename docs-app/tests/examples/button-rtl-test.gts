import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness, IconHarness, SpinnerHarness } from '@ember-joinery/test-support'
import ButtonRtl from 'docs-app/examples/button-rtl'

module('Example | button-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the end is on the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ButtonRtl /></DirectionProvider>
      </template>,
    )
    const [button, remove, submit, add, loading] = ButtonHarness.findAll()
    assert.strictEqual(button!.label, 'زر')
    assert.strictEqual(remove!.variant, 'destructive')
    assert.strictEqual(add!.label, 'إضافة')

    // The icon at the inline end is on the left, mirrored, with the narrower padding beside it.
    const arrow = submit!.find(IconHarness).element
    const box = submit!.element.getBoundingClientRect()
    assert.ok(
      arrow.getBoundingClientRect().left < box.left + box.width / 2,
      'the icon is on the left',
    )
    assert.strictEqual(getComputedStyle(arrow).rotate, '180deg', 'rtl:rotate-180')
    assert.strictEqual(getComputedStyle(submit!.element).paddingLeft, '8px')
    assert.strictEqual(getComputedStyle(submit!.element).paddingRight, '10px')

    assert.true(loading!.isDisabled)
    assert.strictEqual(loading!.find(SpinnerHarness).label, 'جاري التحميل')
    await a11yAudit()
  })
})
