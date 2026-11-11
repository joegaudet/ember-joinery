import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, TextareaHarness } from '@ember-joinery/test-support'
import TextareaDisabled from 'docs-app/examples/textarea-disabled'

module('Example | textarea-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled textarea in a field shown disabled', async function (assert) {
    await render(<template><TextareaDisabled /></template>)
    const field = new FieldHarness()
    const message = field.find(TextareaHarness)

    assert.true(message.isDisabled)
    assert.true(field.isDisabled)
    assert.strictEqual(getComputedStyle(field.labelElement!).opacity, '0.5')
    assert.strictEqual(message.label, 'Message')
    await a11yAudit()
  })
})
