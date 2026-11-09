import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import PortalStargate from 'docs-app/examples/portal-stargate'

/** The example, in a root of the test's own: where the portal is, and the named target. */
class StargateHarness extends Harness {
  static override component = 'portal-stargate'

  /** The fieldset the `<Portal>` is in. */
  get origin(): HTMLFieldSetElement {
    return this.element.querySelector('fieldset')!
  }

  /** The `<PortalTarget>`, rendered after the fieldset. */
  get target(): Element | null {
    return this.origin.nextElementSibling
  }
}

module('Example | portal-stargate', function (hooks) {
  setupRenderingTest(hooks)

  test('a PortalTarget registered by name, after the portal', async function (assert) {
    await render(
      <template>
        <div data-test-jn="portal-stargate"><PortalStargate /></div>
      </template>,
    )
    const example = new StargateHarness()
    assert.dom(example.origin).doesNotContainText('content')
    assert.dom(example.target).hasText('content', 'rendered in the target')
    await a11yAudit()
  })
})
