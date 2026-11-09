import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { CardHarness, TabsHarness } from '@ember-joinery/test-support'
import TabsRtl from 'docs-app/examples/tabs-rtl'

module('Example | tabs-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the tabs run from the right, and the left arrow moves forward', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><TabsRtl /></DirectionProvider>
      </template>,
    )
    const tabs = new TabsHarness()
    assert.deepEqual(
      tabs.tabValues.map(value => tabs.label(value)),
      ['نظرة عامة', 'التحليلات', 'التقارير', 'الإعدادات'],
    )
    assert.strictEqual(tabs.selected, 'overview')
    const card = new CardHarness({ within: tabs.panel! })
    assert.strictEqual(card.title, 'نظرة عامة')
    assert.strictEqual(card.content.textContent!.trim(), 'لديك ١٢ مشروعًا نشطًا و٣ مهام معلقة.')

    const first = tabs.trigger('overview').getBoundingClientRect()
    const second = tabs.trigger('analytics').getBoundingClientRect()
    assert.true(first.left > second.left, 'the first tab is on the right')
    const words = document.createRange()
    words.selectNodeContents(card.part('title'))
    const title = words.getBoundingClientRect()
    const box = card.element.getBoundingClientRect()
    assert.true(box.right - title.right < title.left - box.left, 'its title starts at the right')

    await tabs.focus('overview')
    await tabs.press('ArrowLeft')
    assert.strictEqual(tabs.selected, 'analytics', 'left is forward, right to left')
    assert.strictEqual(new CardHarness({ within: tabs.panel! }).title, 'التحليلات')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.selected, 'overview')
    await a11yAudit()
  })
})
