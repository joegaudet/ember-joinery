import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { click, find, select, visit } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToasterHarness, press } from '@ember-joinery/test-support'

const FRAME = '[data-test-example="sonner-demo"]'

module('Acceptance | the guide’s Toaster', function (hooks) {
  setupApplicationTest(hooks)

  test('the examples’ toasts take the look of the preview they come from', async function (assert) {
    await visit('/components/sonner.md')
    const stage = () => find('.guide-toaster') as HTMLElement
    assert
      .dom(stage())
      .hasAttribute('data-style', 'nova', 'Nova, until a preview lends its look')
      .doesNotHaveClass('dark')

    await select(`${FRAME} [data-test-example-style]`, 'lyra')
    await click(`${FRAME} [data-test-example-dark]`)
    await click(`${FRAME} [data-test-example-rtl]`)
    await press(find(`${FRAME} .example-preview [data-slot="button"]`)!)
    const toaster = new ToasterHarness()
    await toaster.waitForToast('Event has been created')

    assert
      .dom(stage())
      .hasAttribute('data-style', 'lyra')
      .hasClass('dark')
      .hasAttribute('dir', 'rtl')
    assert.true(
      stage().getAttribute('style')?.includes('--radius'),
      "the preview's tokens: its base colour and radius",
    )
    assert.strictEqual(toaster.theme, 'dark', 'dark, as the preview is')
    assert.dom(toaster.lists[0]).hasAttribute('dir', 'rtl')
    await a11yAudit()
  })
})
