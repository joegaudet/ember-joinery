import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, TextareaHarness } from '@ember-joinery/test-support'
import TextareaButton from 'docs-app/examples/textarea-button'

module('Example | textarea-button', function (hooks) {
  setupRenderingTest(hooks)

  test('a textarea with a send button below it, as wide as it', async function (assert) {
    await render(<template><TextareaButton /></template>)
    const textarea = new TextareaHarness()
    const send = new ButtonHarness()

    await textarea.fillIn('Hi there')
    assert.strictEqual(textarea.value, 'Hi there')
    assert.strictEqual(send.label, 'Send message')
    assert.strictEqual(send.variant, 'default')
    const box = textarea.element.getBoundingClientRect()
    const button = send.element.getBoundingClientRect()
    assert.ok(button.top >= box.bottom, 'the button is below')
    assert.strictEqual(Math.round(button.width), Math.round(box.width), 'grid: the same width')
    await a11yAudit()
  })
})
