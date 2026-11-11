import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DrawerHarness } from '@ember-joinery/test-support'
import DrawerSnapPoints from 'docs-app/examples/drawer-snap-points'

module('Example | drawer-snap-points', function (hooks) {
  setupRenderingTest(hooks)

  test('it rests at 148px, 355px or all the way up, and its overlay comes in from the second', async function (assert) {
    await render(<template><DrawerSnapPoints /></template>)
    const drawer = new DrawerHarness()
    const height = window.innerHeight
    await drawer.open()
    await drawer.afterOpening()
    assert.strictEqual(drawer.activeSnapPoint, '148px')
    assert.strictEqual(Math.round(drawer.offset), height - 148, '148px of it showing')
    assert.dom(drawer.overlay).hasAttribute('data-vaul-snap-points-overlay', 'false')
    assert.dom('[aria-live]', drawer.content!).hasText('Resting at 148px')

    await drawer
      .findAll(ButtonHarness)
      .find(button => button.text === '355px')!
      .click()
    drawer.finishAnimations()
    assert.strictEqual(drawer.activeSnapPoint, '355px')
    assert.strictEqual(Math.round(drawer.offset), height - 355)
    assert.dom(drawer.overlay).hasAttribute('data-vaul-snap-points-overlay', 'true')

    await drawer.drag(-(height - 405), { duration: 2400 })
    assert.strictEqual(
      drawer.activeSnapPoint,
      '1',
      'dragged most of the way up, it goes all the way',
    )
    drawer.finishAnimations()
    assert.strictEqual(drawer.offset, 0)
    assert.dom('[aria-live]', drawer.content!).hasText('Resting at 1')
    await a11yAudit()

    await drawer.pressEscape()
    assert.false(drawer.isOpen)
    await a11yAudit()
  })
})
