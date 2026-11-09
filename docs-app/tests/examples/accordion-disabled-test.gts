import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AccordionHarness } from '@ember-joinery/test-support'
import AccordionDisabled from 'docs-app/examples/accordion-disabled'

module('Example | accordion-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('the premium item cannot be opened, and the keys pass over it', async function (assert) {
    await render(<template><AccordionDisabled /></template>)
    const faq = new AccordionHarness()
    assert.deepEqual(faq.openValues, [], 'nothing open to start')
    assert.true(faq.isDisabled('item-2'))
    assert.strictEqual(getComputedStyle(faq.trigger('item-2')).opacity, '0.5')

    await faq.toggle('item-2').catch(() => undefined)
    assert.false(faq.isOpen('item-2'))

    await faq.focus('item-1')
    await faq.press('ArrowDown')
    assert.strictEqual(faq.focused, 'item-3')
    await a11yAudit()
  })
})
