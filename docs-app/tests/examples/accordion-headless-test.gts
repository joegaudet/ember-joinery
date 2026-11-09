import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AccordionHarness } from '@ember-joinery/test-support'
import AccordionHeadless from 'docs-app/examples/accordion-headless'

module('Example | accordion-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('headings with triggers, each revealing its region', async function (assert) {
    await render(<template><AccordionHeadless /></template>)
    const faq = new AccordionHarness()
    assert.deepEqual(faq.titles, ['Is it accessible?', 'Is it styled?', 'Can it be animated?'])
    assert.dom(faq.header('accessible')).hasTagName('h3')

    await faq.open('styled')
    assert.strictEqual(faq.content('styled').getAttribute('role'), 'region')
    assert.strictEqual(
      faq.content('styled').getAttribute('aria-labelledby'),
      faq.trigger('styled').id,
    )
    assert.strictEqual(getComputedStyle(faq.trigger('styled')).textDecorationLine, 'underline')

    await faq.focus('accessible')
    await faq.press('End')
    assert.strictEqual(faq.focused, 'animated')
    await a11yAudit()
  })
})
