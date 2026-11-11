import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, PaginationHarness, SelectHarness } from '@ember-joinery/test-support'
import PaginationIconsOnly from 'docs-app/examples/pagination-icons-only'

module('Example | pagination-icons-only', function (hooks) {
  setupRenderingTest(hooks)

  test('a rows per page select beside previous and next, without page numbers', async function (assert) {
    await render(<template><PaginationIconsOnly /></template>)
    const field = new FieldHarness()
    assert.strictEqual(field.orientation, 'horizontal')
    assert.strictEqual(field.label, 'Rows per page')

    const rows = new SelectHarness()
    assert.strictEqual(rows.label, 'Rows per page')
    assert.strictEqual(rows.valueText, '25')
    await rows.open()
    assert.deepEqual(rows.optionTexts, ['10', '25', '50', '100'])
    await a11yAudit()
    await rows.pressOption('50')
    assert.strictEqual(rows.value, '50')

    const pagination = new PaginationHarness()
    assert.deepEqual(pagination.pages, [], 'no page numbers')
    assert.dom(pagination.previous).hasAttribute('aria-label', 'Go to previous page')
    assert.dom(pagination.next).hasAttribute('aria-label', 'Go to next page')
    await a11yAudit()
  })
})
