import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import DomContextGreeting from 'docs-app/examples/dom-context-greeting'

class GreetingHarness extends Harness {
  static component = 'greeting'

  /** The text as it reads on screen, the template's line breaks collapsed. */
  get text() {
    return this.element.textContent!.replace(/\s+/g, ' ').trim()
  }
}

module('Example | dom-context-greeting', function (hooks) {
  setupRenderingTest(hooks)

  test("the consumer reads the provider's data", async function (assert) {
    await render(<template><DomContextGreeting /></template>)
    assert.strictEqual(new GreetingHarness().text, 'hello, world!')
    await a11yAudit()
  })
})
