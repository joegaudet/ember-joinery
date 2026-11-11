import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputRtl from 'docs-app/examples/input-rtl'

module('Example | input-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the label at the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><InputRtl /></DirectionProvider>
      </template>,
    )
    const field = new FieldHarness()
    const key = field.find(InputHarness)

    assert.strictEqual(key.label, 'مفتاح API')
    assert.strictEqual(field.description, 'مفتاح API الخاص بك مشفر ومخزن بأمان.')
    assert.strictEqual(
      Math.round(field.labelElement!.getBoundingClientRect().right),
      Math.round(field.element.getBoundingClientRect().right),
      'the label starts at the right',
    )
    await a11yAudit()
  })
})
