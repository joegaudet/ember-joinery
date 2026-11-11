import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ButtonHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import SonnerDescription from 'docs-app/examples/sonner-description'

module('Example | sonner-description', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('the toast has a description under its title', async function (assert) {
    await render(
      <template>
        <SonnerDescription />
        <Toaster />
      </template>,
    )
    const button = new ButtonHarness()
    assert.dom(button.element).hasClass('w-fit')
    await button.click()

    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.title, 'Event has been created')
    assert.strictEqual(toast.description, 'Monday, January 3rd at 6:00pm')
    await a11yAudit()
  })
})
