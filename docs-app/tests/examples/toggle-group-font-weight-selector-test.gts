import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, ToggleGroupHarness } from '@ember-joinery/test-support'
import ToggleGroupFontWeightSelector from 'docs-app/examples/toggle-group-font-weight-selector'

/**
 * The audit, but for two of upstream's colours: the pressed item's caption and the description's
 * `<code>` are `--muted-foreground` on `--muted` (about 4.3:1), under the 4.5:1 WCAG AA asks of
 * small text (see the Toggle Group page's Accessibility notes). Everything else is audited.
 */
const BUT_MUTED_ON_MUTED = {
  include: [['#ember-testing-container']],
  exclude: [
    ['[data-slot="toggle-group-item"][data-state="on"] .text-muted-foreground'],
    ['[data-slot="field-description"] code'],
  ],
}

module('Example | toggle-group-font-weight-selector', function (hooks) {
  setupRenderingTest(hooks)

  test('four weights in a field, one at a time, which the description names', async function (assert) {
    await render(<template><ToggleGroupFontWeightSelector /></template>)
    const field = new FieldHarness()
    const weight = field.find(ToggleGroupHarness)

    assert.strictEqual(field.label, 'Font Weight')
    assert.dom(weight.element).hasAria('labelledby', field.labelElement!.id)
    assert.deepEqual(weight.itemValues, ['light', 'normal', 'medium', 'bold'])
    assert.deepEqual(weight.value, ['normal'])
    assert.strictEqual(weight.variant, 'outline')
    assert.strictEqual(weight.size, 'lg')
    assert.strictEqual(weight.spacing, 2)
    assert.strictEqual(field.description, 'Use font-normal to set the font weight.')
    assert.strictEqual(weight.item('bold').offsetWidth, 64, 'each item size-16')

    await weight.toggle('bold')
    assert.deepEqual(weight.value, ['bold'])
    assert.strictEqual(field.description, 'Use font-bold to set the font weight.')

    await weight.focus('bold')
    await weight.press('ArrowLeft')
    assert.strictEqual(weight.focused, 'medium', 'the arrows move between the weights')
    await weight.toggle('medium')
    assert.deepEqual(weight.value, ['medium'], 'one weight at a time')
    assert.strictEqual(field.description, 'Use font-medium to set the font weight.')
    await a11yAudit(BUT_MUTED_ON_MUTED)
  })
})
