import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ButtonHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import SonnerPosition from 'docs-app/examples/sonner-position'

const POSITIONS = [
  'top-left',
  'top-center',
  'top-right',
  'bottom-left',
  'bottom-center',
  'bottom-right',
]

module('Example | sonner-position', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('each button shows the toast in its corner, in a list of its own', async function (assert) {
    await render(
      <template>
        <SonnerPosition />
        <Toaster />
      </template>,
    )
    const buttons = ButtonHarness.findAll()
    assert.deepEqual(
      buttons.map(button => button.label),
      ['Top Left', 'Top Center', 'Top Right', 'Bottom Left', 'Bottom Center', 'Bottom Right'],
    )
    for (const button of buttons) await button.click()

    const toaster = new ToasterHarness()
    assert.deepEqual(
      [...toaster.positions].sort(),
      [...POSITIONS].sort(),
      'one list for each position',
    )
    for (const position of POSITIONS) {
      const toast = toaster.toasts.find(each => each.position === position)
      assert.strictEqual(toast?.title, 'Event has been created', `a toast at ${position}`)
    }
    const topLeft = toaster.lists.find(list => list.dataset['testJnValue'] === 'top-left')!
    const box = topLeft.getBoundingClientRect()
    assert.strictEqual(box.left, 24, '24px from the left')
    assert.strictEqual(box.top, 24, 'and the top')
    await a11yAudit()
  })
})
