import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import NarrowingGuards from 'docs-app/examples/narrowing-guards'

/** The table: each row's answers, in column order. */
class GuardsHarness extends Harness {
  static component = 'guards'

  answers(label: string) {
    return [...this.part('row', label).querySelectorAll('td')].map(cell => cell.textContent!.trim())
  }
}

module('Example | narrowing-guards', function (hooks) {
  setupRenderingTest(hooks)

  test('each guard answers for each value', async function (assert) {
    await render(<template><NarrowingGuards /></template>)
    const table = new GuardsHarness()
    assert.deepEqual(table.answers("'hello'"), ['yes', 'no', 'no'])
    assert.deepEqual(table.answers('42'), ['no', 'no', 'no'])
    assert.deepEqual(table.answers('a <p> element'), ['no', 'yes', 'no'])
    assert.deepEqual(table.answers('class Card'), ['no', 'no', 'yes'])
    assert.deepEqual(table.answers('() => new Card()'), ['no', 'no', 'no'])
    await a11yAudit()
  })
})
