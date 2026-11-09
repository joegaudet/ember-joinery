import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import AsPart from 'docs-app/examples/as-part'

/** The example's collapsible. Both elements are its `trigger` part, so it finds both. */
class CollapsibleHarness extends Harness {
  static component = 'collapsible'

  /** Every element that is the trigger: the part's own button, then the link. */
  get triggers() {
    return this.parts('trigger')
  }

  get content() {
    return this.part('content')
  }

  get isOpen() {
    return this.triggers[0]!.getAttribute('aria-expanded') === 'true'
  }

  async toggle(trigger: HTMLElement) {
    await click(trigger)
  }
}

module('Example | as-part', function (hooks) {
  setupRenderingTest(hooks)

  test('the part component and the part modifier are both the trigger', async function (assert) {
    await render(<template><AsPart /></template>)
    const collapsible = new CollapsibleHarness()
    const [button, link] = collapsible.triggers

    assert.dom(button).hasTagName('button').hasAria('expanded', 'false')
    assert.dom(link).hasTagName('a').hasAria('expanded', 'false', 'the link is the same part')
    assert.dom(collapsible.content).isNotVisible()

    await collapsible.toggle(link!)
    assert.true(collapsible.isOpen, 'the link opened it')
    assert.dom(collapsible.content).isVisible()
    assert.dom(link).hasAria('expanded', 'true').hasAttribute('data-state', 'open')

    await collapsible.toggle(button!)
    assert.false(collapsible.isOpen, 'and the button closed it')
    assert.dom(collapsible.content).isNotVisible()
    await a11yAudit()
  })
})
