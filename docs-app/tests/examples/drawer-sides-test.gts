import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DrawerHarness } from '@ember-joinery/test-support'
import DrawerSides from 'docs-app/examples/drawer-sides'

module('Example | drawer-sides', function (hooks) {
  setupRenderingTest(hooks)

  test('one drawer from each edge', async function (assert) {
    await render(<template><DrawerSides /></template>)
    const drawers = DrawerHarness.findAll()
    assert.deepEqual(
      drawers.map(drawer => new ButtonHarness({ within: drawer }).text),
      ['top', 'right', 'bottom', 'left'],
    )

    for (const drawer of drawers) {
      await drawer.open()
      const direction = drawer.direction!
      drawer.finishAnimations()
      const rect = drawer.content!.getBoundingClientRect()
      if (direction === 'top' || direction === 'bottom') {
        assert.ok(
          rect.height <= window.innerHeight / 2 + 1,
          `${direction}: at most half the screen`,
        )
      } else {
        assert.strictEqual(Math.round(rect.height), window.innerHeight, `${direction}: full height`)
      }
      if (direction === 'top') assert.strictEqual(rect.top, 0)
      if (direction === 'right') assert.strictEqual(Math.round(rect.right), window.innerWidth)
      if (direction === 'bottom') assert.strictEqual(Math.round(rect.bottom), window.innerHeight)
      if (direction === 'left') assert.strictEqual(rect.left, 0)
      assert.strictEqual(drawer.label, 'Move Goal', `${direction}: named by its title`)
      await a11yAudit()
      await drawer
        .findAll(ButtonHarness)
        .find(button => button.text === 'Cancel')!
        .click()
      assert.false(drawer.isOpen, `${direction}: its Cancel closes it`)
    }
    await a11yAudit()
  })
})
