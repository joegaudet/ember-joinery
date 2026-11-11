import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { FieldHarness, TextareaHarness } from '@ember-joinery/test-support'
import TextareaRtl from 'docs-app/examples/textarea-rtl'

module('Example | textarea-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the label and text from the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><TextareaRtl /></DirectionProvider>
      </template>,
    )
    const field = new FieldHarness()
    const feedback = field.find(TextareaHarness)

    assert.strictEqual(feedback.label, 'التعليقات')
    assert.strictEqual(field.description, 'شاركنا أفكارك حول خدمتنا.')
    assert.strictEqual(feedback.control.rows, 4)
    assert.strictEqual(getComputedStyle(field.labelElement!).direction, 'rtl')
    assert.strictEqual(
      Math.round(field.labelElement!.getBoundingClientRect().right),
      Math.round(field.element.getBoundingClientRect().right),
      'the label starts at the right',
    )
    await a11yAudit()
  })
})
