import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ComboboxHarness, FieldHarness } from '@ember-joinery/test-support'
import ComboboxRtl from 'docs-app/examples/combobox-rtl'

module('Example | combobox-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic, categories pile up as chips', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ComboboxRtl /></DirectionProvider>
      </template>,
    )
    const field = new FieldHarness()
    assert.strictEqual(field.label, 'الفئات')
    const combobox = new ComboboxHarness()
    assert.deepEqual(combobox.chips, ['technology'], 'it starts with the first')
    assert.dom(combobox.chip('technology')).hasText('التكنولوجيا')
    assert.strictEqual(combobox.placeholder, 'أضف فئات')

    const chips = combobox.part('chips').getBoundingClientRect()
    const chip = combobox.chip('technology').getBoundingClientRect()
    assert.true(chip.right > chips.right - 20, 'the first chip is at the right, the start')

    await combobox.open()
    assert.dom(combobox.content).hasAttribute('dir', 'rtl').hasAttribute('data-lang', 'ar')
    assert.strictEqual(combobox.highlighted, 'technology', 'autoHighlight')
    assert.deepEqual(combobox.itemTexts, [
      'التكنولوجيا',
      'التصميم',
      'الأعمال',
      'التسويق',
      'التعليم',
      'الصحة',
    ])
    await combobox.pressItem('design')
    assert.deepEqual(combobox.chips, ['technology', 'design'])
    await a11yAudit()

    await combobox.removeChip('technology')
    assert.deepEqual(combobox.chips, ['design'])
    await a11yAudit()
  })
})
