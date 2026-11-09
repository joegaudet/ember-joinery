import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import PortalStargate from 'docs-app/examples/portal-stargate'

module('Example | portal-stargate', function (hooks) {
  setupRenderingTest(hooks)

  test('a PortalTarget registered by name, after the portal', async function (assert) {
    await render(<template><PortalStargate /></template>)
    assert.dom('fieldset').doesNotContainText('content')
    const target = document.querySelector('fieldset')!.nextElementSibling
    assert.dom(target).hasText('content', 'rendered in the target')
    await a11yAudit()
  })
})
