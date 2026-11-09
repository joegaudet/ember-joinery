import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputHarness } from '@ember-joinery/test-support'
import InputBasic from 'docs-app/examples/input-basic'

module('Example | input-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('a text input, named by its placeholder, that takes what you type', async function (assert) {
    await render(<template><InputBasic /></template>)
    const input = new InputHarness()

    assert.strictEqual(input.type, 'text')
    assert.strictEqual(input.placeholder, 'Enter text')
    assert.strictEqual(input.label, 'Enter text', 'with nothing else, the placeholder names it')
    await input.fillIn('Hello')
    assert.strictEqual(input.value, 'Hello')
    await a11yAudit()
  })
})
