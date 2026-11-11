import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AccordionHarness } from '@ember-joinery/test-support'
import AccordionBasic from 'docs-app/examples/accordion-basic'

module('Example | accordion-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('one item at a time, the first open to start', async function (assert) {
    await render(<template><AccordionBasic /></template>)
    const faq = new AccordionHarness()
    assert.deepEqual(faq.itemValues, ['item-1', 'item-2', 'item-3'])
    assert.deepEqual(faq.openValues, ['item-1'])
    assert.strictEqual(faq.title('item-1'), 'How do I reset my password?')

    await faq.open('item-3')
    assert.deepEqual(faq.openValues, ['item-3'], 'opening one closes the other')
    assert.strictEqual(
      faq.text('item-3'),
      'We accept all major credit cards, PayPal, and bank transfers. All payments are processed securely through our payment partners.',
    )
    await a11yAudit()
  })
})
