import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, LabelHarness, RadioGroupHarness } from '@ember-joinery/test-support'
import RadioGroupDescription from 'docs-app/examples/radio-group-description'

module('Example | radio-group-description', function (hooks) {
  setupRenderingTest(hooks)

  test('each choice with a description beside its radio', async function (assert) {
    await render(<template><RadioGroupDescription /></template>)
    const spacing = new RadioGroupHarness()

    assert.deepEqual(spacing.options, ['default', 'comfortable', 'compact'])
    assert.strictEqual(spacing.value, 'comfortable')
    assert.deepEqual(
      FieldHarness.findAll().map(field => field.description),
      [
        'Standard spacing for most use cases.',
        'More space between elements.',
        'Minimal spacing for dense layouts.',
      ],
    )
    assert.strictEqual(spacing.labelOf('compact'), 'Compact')
    await LabelHarness.findAll()[2]!.click()
    assert.strictEqual(spacing.value, 'compact')
    await a11yAudit()
  })
})
