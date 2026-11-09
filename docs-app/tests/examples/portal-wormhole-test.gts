import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { waitForObservers } from '@ember-joinery/test-support'
import PortalWormhole from 'docs-app/examples/portal-wormhole'

module('Example | portal-wormhole', function (hooks) {
  setupRenderingTest(hooks)

  test('an id, or a selector, finds an element rendered after the portals', async function (assert) {
    await render(<template><PortalWormhole /></template>)
    await waitForObservers() // the InViewport renders it once in view
    assert.dom('#wormhole-target').hasText('content extra content', 'both appended, in order')
    assert.dom('fieldset').doesNotContainText('content')
    await a11yAudit()
  })
})
