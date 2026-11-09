import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, waitForObservers } from '@ember-joinery/test-support'
import PortalWormhole from 'docs-app/examples/portal-wormhole'

/** The example, in a root of the test's own: where the portals are, and the element they find. */
class WormholeHarness extends Harness {
  static override component = 'portal-wormhole'

  /** The fieldset the two `<Portal>`s are in. */
  get origin(): HTMLFieldSetElement {
    return this.element.querySelector('fieldset')!
  }

  /** The element whose id they name, rendered after them. */
  get target(): HTMLElement {
    return this.element.querySelector('#wormhole-target')!
  }
}

module('Example | portal-wormhole', function (hooks) {
  setupRenderingTest(hooks)

  test('an id, or a selector, finds an element rendered after the portals', async function (assert) {
    await render(
      <template>
        <div data-test-jn="portal-wormhole"><PortalWormhole /></div>
      </template>,
    )
    await waitForObservers() // the InViewport renders it once in view
    const example = new WormholeHarness()
    assert.dom(example.target).hasText('content extra content', 'both appended, in order')
    assert.dom(example.origin).doesNotContainText('content')
    await a11yAudit()
  })
})
