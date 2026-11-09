import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import PortalElement from 'docs-app/examples/portal-element'

module('Example | portal-element', function (hooks) {
  setupRenderingTest(hooks)

  test('the content renders in the element, wherever that is', async function (assert) {
    await render(<template><PortalElement /></template>)
    assert.dom('fieldset').doesNotContainText('content', 'not where the portal is')
    const element = document.querySelector('fieldset')!.nextElementSibling
    assert.dom(element).hasTagName('div').hasText('content', 'but in the element, rendered after')
    await a11yAudit()
  })
})
