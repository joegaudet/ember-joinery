import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PopoverHarness } from '@ember-joinery/test-support'
import PopoverAlignments from 'docs-app/examples/popover-alignments'

module('Example | popover-alignments', function (hooks) {
  setupRenderingTest(hooks)

  test('each popover lines up with its button’s start, centre or end', async function (assert) {
    await render(<template><PopoverAlignments /></template>)
    const popovers = PopoverHarness.findAll()
    assert.strictEqual(popovers.length, 3)

    const aligns = [
      ['start', 'Start'],
      ['center', 'Center'],
      ['end', 'End'],
    ] as const
    for (const [index, [align, label]] of aligns.entries()) {
      const popover = popovers[index]!
      await popover.open()
      assert.strictEqual(popover.align, align)
      assert.strictEqual(popover.text, `Aligned to ${align}`)
      assert.strictEqual(popover.label, label, 'named by its button')
      for (const animation of popover.content!.getAnimations()) animation.finish()
      assert.strictEqual(getComputedStyle(popover.content!).width, '160px', 'w-40')
      const t = popover.trigger.getBoundingClientRect()
      const c = popover.content!.getBoundingClientRect()
      const edge =
        align === 'start'
          ? c.left - t.left
          : align === 'end'
            ? c.right - t.right
            : c.left + c.width / 2 - (t.left + t.width / 2)
      assert.true(Math.abs(edge) <= 1, `aligned to ${align}`)
      await a11yAudit()
      await popover.close()
    }
  })
})
