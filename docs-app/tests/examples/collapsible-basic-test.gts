import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CardHarness, CollapsibleHarness } from '@ember-joinery/test-support'
import CollapsibleBasic from 'docs-app/examples/collapsible-basic'

module('Example | collapsible-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('a full-width ghost button in a card shows and hides the product details', async function (assert) {
    await render(<template><CollapsibleBasic /></template>)
    const card = new CardHarness()
    const details = card.find(CollapsibleHarness)
    const toggle = details.find(ButtonHarness)

    assert.strictEqual(details.trigger, toggle.element, 'the ghost Button is the trigger')
    assert.strictEqual(toggle.variant, 'ghost')
    assert.strictEqual(details.label, 'Product details')
    assert.true(details.controlsContent)
    assert.strictEqual(toggle.element.offsetWidth, details.element.clientWidth, 'w-full')
    const chevron = toggle.element.querySelector('svg')!
    assert.strictEqual(getComputedStyle(chevron).rotate, 'none', 'the chevron points down')
    assert.strictEqual(
      getComputedStyle(details.element).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'no fill while closed',
    )
    assert.false(details.isShown, 'the details start hidden')

    await details.open()
    assert.true(details.isOpen)
    assert.strictEqual(
      details.text,
      'This panel can be expanded or collapsed to reveal additional content. Learn More',
    )
    assert.notStrictEqual(
      getComputedStyle(details.element).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'the open panel takes the muted fill',
    )
    assert.strictEqual(getComputedStyle(chevron).rotate, '180deg', 'the chevron turns up')
    const learnMore = new ButtonHarness({ within: details.content! })
    assert.strictEqual(learnMore.label, 'Learn More')
    assert.strictEqual(learnMore.size, 'xs')

    await toggle.click()
    assert.false(details.isOpen)
    assert.false(details.isShown, 'the same button hides them again')
    await a11yAudit()
  })
})
