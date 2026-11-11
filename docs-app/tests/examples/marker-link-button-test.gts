import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import { MarkerHarness, ToasterHarness, setupToaster, tab } from '@ember-joinery/test-support'
import MarkerLinkButton from 'docs-app/examples/marker-link-button'

module('Example | marker-link-button', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a marker that links, and one that is a button, both in the tab order', async function (assert) {
    // The app renders its Toaster once, in its application template; a test renders its own.
    await render(
      <template>
        <MarkerLinkButton />
        <Toaster />
      </template>,
    )
    const [link, button] = MarkerHarness.findAll()

    assert.true(link!.isLink)
    assert.strictEqual(link!.href, '#links-and-buttons')
    assert.strictEqual(link!.label, 'View the pull request', 'named by its text, not its icon')
    assert.strictEqual(getComputedStyle(link!.element).textDecorationLine, 'underline')

    assert.true(button!.isButton)
    assert.strictEqual(button!.label, 'Revert this change')

    await tab()
    assert.true(link!.isFocused, 'Tab reaches the link')
    await tab()
    assert.true(button!.isFocused, 'and then the button')

    await button!.click()
    assert.strictEqual(new ToasterHarness().toast().title, 'You clicked the revert button')
    await a11yAudit()
  })
})
