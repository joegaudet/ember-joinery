import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { FieldHarness, RadioGroupHarness, tab } from '@ember-joinery/test-support'
import RadioGroupRtl from 'docs-app/examples/radio-group-rtl'

module('Example | radio-group-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, each radio on the right of its label; the arrows swap', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><RadioGroupRtl /></DirectionProvider>
      </template>,
    )
    const spacing = new RadioGroupHarness()
    const [first] = FieldHarness.findAll()

    assert.strictEqual(spacing.value, 'comfortable')
    assert.strictEqual(spacing.labelOf('default'), 'افتراضي')
    assert.strictEqual(first!.description, 'تباعد قياسي لمعظم حالات الاستخدام.')
    assert.true(
      spacing.item('default').getBoundingClientRect().left >
        first!.labelElement!.getBoundingClientRect().right,
      'the radio comes first, on the right',
    )
    await tab()
    await spacing.press('ArrowLeft')
    assert.strictEqual(spacing.value, 'compact', 'ArrowLeft moves on, right to left')
    await a11yAudit()
  })
})
