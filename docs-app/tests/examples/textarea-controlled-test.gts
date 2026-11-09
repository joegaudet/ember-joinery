import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, TextareaHarness } from '@ember-joinery/test-support'
import TextareaControlled from 'docs-app/examples/textarea-controlled'

module('Example | textarea-controlled', function (hooks) {
  setupRenderingTest(hooks)

  test('the parent owns the message: it counts it, and clears it', async function (assert) {
    await render(<template><TextareaControlled /></template>)
    const message = new TextareaHarness('message')
    const left = () => find('[data-test-left]')!.textContent!.trim()

    assert.strictEqual(message.label, 'Message')
    assert.strictEqual(left(), '280')
    await message.fillIn('Hello')
    assert.strictEqual(left(), '275', '@onValueChange told the parent')

    await new ButtonHarness('clear').click()
    assert.strictEqual(message.value, '', 'and @value empties it')
    assert.strictEqual(left(), '280')
    await a11yAudit()
  })
})
