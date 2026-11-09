import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import PortalNesting from 'docs-app/examples/portal-nesting'

/** The text a layer shows itself, leaving out the layers inside it. */
function ownText(element: Element): string {
  return [...element.childNodes]
    .filter(node => node.nodeType === Node.TEXT_NODE)
    .map(node => node.textContent!.trim())
    .join('')
}

/** The example, in a root of the test's own: its layers, each in the target above it. */
class NestingHarness extends Harness {
  static override component = 'portal-nesting'

  /**
   * The text of each layer, outermost first: the layer rendered in the page's target, then the
   * one rendered in that layer's own target, and so on.
   */
  get layers(): string[] {
    const layers: string[] = []
    let target = this.element.querySelector('.style-wrapper > [data-portal-target]')
    while (target) {
      const layer = target.querySelector(':scope > .popover')
      if (!layer) break
      layers.push(ownText(layer))
      target = layer.querySelector(':scope > [data-portal-target]')
    }
    return layers
  }
}

module('Example | portal-nesting', function (hooks) {
  setupRenderingTest(hooks)

  test('each layer renders in the nearest target above it', async function (assert) {
    await render(
      <template>
        <div data-test-jn="portal-nesting"><PortalNesting /></div>
      </template>,
    )
    assert.deepEqual(
      new NestingHarness().layers,
      ['first layer', 'second layer', 'tooltip / third layer'],
      'the first in the top target, each of the others in the target of the layer above it',
    )
    await a11yAudit()
  })
})
