import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AccordionHarness } from '@ember-joinery/test-support'
import AccordionDemo from 'docs-app/examples/accordion-demo'

module('Example | accordion-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('three questions, the first open, and every one can close', async function (assert) {
    await render(<template><AccordionDemo /></template>)
    const faq = new AccordionHarness()
    assert.deepEqual(faq.titles, [
      'What are your shipping options?',
      'What is your return policy?',
      'How can I contact customer support?',
    ])
    assert.deepEqual(faq.openValues, ['shipping'])
    assert.strictEqual(
      faq.text('shipping'),
      'We offer standard (5-7 days), express (2-3 days), and overnight shipping. Free shipping on international orders.',
    )

    await faq.toggle('returns')
    assert.deepEqual(faq.openValues, ['returns'], 'one at a time')
    await faq.toggle('returns')
    assert.deepEqual(faq.openValues, [], 'collapsible: none open')

    await faq.focus('shipping')
    await faq.press('ArrowDown')
    assert.strictEqual(faq.focused, 'returns', 'the arrow keys move between questions')
    await a11yAudit()
  })
})
