import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AccordionHarness } from '@ember-joinery/test-support'
import AccordionRtl from 'docs-app/examples/accordion-rtl'

module('Example | accordion-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the questions start on the right and the chevrons sit at the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><AccordionRtl /></DirectionProvider>
      </template>,
    )
    const faq = new AccordionHarness()
    assert.strictEqual(faq.title('item-1'), 'كيف يمكنني إعادة تعيين كلمة المرور؟')
    assert.deepEqual(faq.openValues, ['item-1'])

    const trigger = faq.trigger('item-2')
    const chevron = [...trigger.querySelectorAll('svg')].find(
      svg => getComputedStyle(svg).display !== 'none',
    )!
    const box = trigger.getBoundingClientRect()
    assert.ok(
      chevron.getBoundingClientRect().left < box.left + box.width / 2,
      'the chevron is at the inline end, the left',
    )
    assert.strictEqual(getComputedStyle(trigger).textAlign, 'start')

    await faq.open('item-3')
    assert.deepEqual(faq.openValues, ['item-3'])
    await a11yAudit()
  })
})
