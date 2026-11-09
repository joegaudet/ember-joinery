import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputInline from 'docs-app/examples/input-inline'

module('Example | input-inline', function (hooks) {
  setupRenderingTest(hooks)

  test('a search input and its button on one row', async function (assert) {
    await render(<template><InputInline /></template>)
    const field = new FieldHarness()
    const search = field.find(InputHarness)
    const button = field.find(ButtonHarness)

    assert.strictEqual(search.type, 'search')
    assert.strictEqual(search.label, 'Search')
    assert.strictEqual(button.text, 'Search')
    assert.strictEqual(
      Math.round(search.element.getBoundingClientRect().top),
      Math.round(button.element.getBoundingClientRect().top),
      'side by side',
    )
    await search.fillIn('shadcn')
    assert.strictEqual(search.value, 'shadcn')
    await a11yAudit()
  })
})
