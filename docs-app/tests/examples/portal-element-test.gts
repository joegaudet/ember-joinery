import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import PortalElement from 'docs-app/examples/portal-element'

/** The example, in a root of the test's own: where the portal is, and the element it renders in. */
class PortalElementHarness extends Harness {
  static override component = 'portal-element'

  /** The fieldset the `<Portal>` is in. */
  get origin(): HTMLFieldSetElement {
    return this.element.querySelector('fieldset')!
  }

  /** The element the example creates, rendered after the fieldset. */
  get target(): Element | null {
    return this.origin.nextElementSibling
  }
}

module('Example | portal-element', function (hooks) {
  setupRenderingTest(hooks)

  test('the content renders in the element, wherever that is', async function (assert) {
    await render(
      <template>
        <div data-test-jn="portal-element"><PortalElement /></div>
      </template>,
    )
    const example = new PortalElementHarness()
    assert.dom(example.origin).doesNotContainText('content', 'not where the portal is')
    assert.dom(example.target).hasTagName('div').hasText('content', 'but in the element')
    await a11yAudit()
  })
})
