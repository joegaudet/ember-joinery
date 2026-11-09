import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DrawerHarness } from '@ember-joinery/test-support'
import DrawerNonDismissible from 'docs-app/examples/drawer-non-dismissible'

module('Example | drawer-non-dismissible', function (hooks) {
  setupRenderingTest(hooks)

  test('only its own button closes it', async function (assert) {
    await render(<template><DrawerNonDismissible /></template>)
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    await drawer.pressEscape()
    assert.true(drawer.isOpen, 'not Escape')
    await drawer.pressOutside()
    assert.true(drawer.isOpen, 'not a press outside')
    await drawer.drag(200)
    assert.true(drawer.isOpen, 'not a drag')
    await a11yAudit()

    await drawer
      .findAll(ButtonHarness)
      .find(button => button.text === 'Got it')!
      .click()
    assert.false(drawer.isOpen, '“Got it” does')
    await a11yAudit()
  })
})
