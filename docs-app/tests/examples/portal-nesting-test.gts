import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import PortalNesting from 'docs-app/examples/portal-nesting'

/** The text a layer shows itself, leaving out the layers inside it. */
function ownText(element: Element): string {
  return [...element.childNodes]
    .filter(node => node.nodeType === Node.TEXT_NODE)
    .map(node => node.textContent!.trim())
    .join('')
}

module('Example | portal-nesting', function (hooks) {
  setupRenderingTest(hooks)

  test('each layer renders in the nearest target above it', async function (assert) {
    await render(<template><PortalNesting /></template>)
    const [top] = document.querySelectorAll('.style-wrapper > [data-portal-target]')
    const first = top!.querySelector(':scope > .popover')!
    assert.strictEqual(ownText(first), 'first layer', 'in the top target')

    const second = first.querySelector(':scope > [data-portal-target] > .popover')!
    assert.strictEqual(ownText(second), 'second layer', 'in the first layer’s target')

    const third = second.querySelector(':scope > [data-portal-target] > .popover')!
    assert.strictEqual(ownText(third), 'tooltip / third layer', 'in the second layer’s')
    await a11yAudit()
  })
})
