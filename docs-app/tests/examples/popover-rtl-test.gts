import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { PopoverHarness } from '@ember-joinery/test-support'
import PopoverRtl from 'docs-app/examples/popover-rtl'

module('Example | popover-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, each popover opens on its own physical side', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><PopoverRtl /></DirectionProvider>
      </template>,
    )
    const popovers = PopoverHarness.findAll()
    assert.deepEqual(
      popovers.map(popover => popover.trigger.textContent?.trim()),
      ['يسار', 'أعلى', 'أسفل', 'يمين'],
    )

    const sides = ['left', 'top', 'bottom', 'right']
    for (const [index, popover] of popovers.entries()) {
      await popover.open()
      assert.strictEqual(popover.label, 'الأبعاد')
      assert.strictEqual(popover.description, 'تعيين الأبعاد للطبقة.')
      assert.dom(popover.content).hasAttribute('dir', 'rtl')
      // It flips where there's no room, so check it went to the side asked for or its opposite.
      const side = sides[index]!
      const opposite = { left: 'right', right: 'left', top: 'bottom', bottom: 'top' }[side]
      assert.true([side, opposite].includes(popover.side!), `${side}: placed on ${popover.side}`)
      await a11yAudit()
      await popover.close()
    }
  })
})
