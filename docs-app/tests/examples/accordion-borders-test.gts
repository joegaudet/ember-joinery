import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AccordionHarness } from '@ember-joinery/test-support'
import AccordionBorders from 'docs-app/examples/accordion-borders'

module('Example | accordion-borders', function (hooks) {
  setupRenderingTest(hooks)

  test('a bordered, rounded accordion with padded items', async function (assert) {
    await render(<template><AccordionBorders /></template>)
    const faq = new AccordionHarness()
    const style = getComputedStyle(faq.element)
    assert.strictEqual(style.borderTopWidth, '1px', 'border')
    assert.notStrictEqual(style.borderTopLeftRadius, '0px', 'rounded-lg')

    const [first, , last] = faq.itemValues.map(value => getComputedStyle(faq.item(value)))
    assert.strictEqual(first!.borderBottomWidth, '1px', 'border-b')
    assert.strictEqual(last!.borderBottomWidth, '0px', 'last:border-b-0')
    assert.strictEqual(first!.paddingLeft, '16px', 'px-4')

    assert.deepEqual(faq.openValues, ['billing'])
    await faq.open('security')
    assert.deepEqual(faq.openValues, ['security'])
    await a11yAudit()
  })
})
