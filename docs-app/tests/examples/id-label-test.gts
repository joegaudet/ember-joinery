import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import IdLabel from 'docs-app/examples/id-label'

/** The example's field. Its parts are found by `data-test-jn-part`, never by their ids. */
class EmailFieldHarness extends Harness {
  static component = 'email-field'

  get input() {
    return this.part<HTMLInputElement>('input')
  }

  get label() {
    return this.part<HTMLLabelElement>('label')
  }

  get hint() {
    return this.part('hint')
  }
}

module('Example | id-label', function (hooks) {
  setupRenderingTest(hooks)

  test('the ids tie the label and the hint to the input', async function (assert) {
    await render(<template><IdLabel /></template>)
    const field = new EmailFieldHarness()

    assert.strictEqual(field.input.labels?.[0], field.label, 'the label names the input')
    assert.dom(field.input).hasAttribute('aria-describedby', field.hint.id)
    assert.notStrictEqual(field.input.id, field.hint.id, 'two different ids')
    await a11yAudit()
  })
})
