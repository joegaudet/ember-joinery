import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SelectHarness } from '@ember-joinery/test-support'
import SelectHeadless from 'docs-app/examples/select-headless'

module('Example | select-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the headless select, below its trigger, named by its label', async function (assert) {
    await render(<template><SelectHeadless /></template>)
    const select = new SelectHarness()
    assert.strictEqual(select.label, 'Fruit')
    assert.strictEqual(select.valueText, 'Banana')
    await select.open()
    assert.strictEqual(select.position, 'popper')
    assert.strictEqual(select.side, 'bottom')
    assert.true(select.isOptionSelected('banana'))
    assert.true(select.isOptionDisabled('cherry'))
    assert.dom('[data-test-jn-part="option-indicator"]', select.option('banana')).hasText('✓')
    await select.pressKey('ArrowUp')
    await select.pressKey('Enter')
    assert.strictEqual(select.valueText, 'Apple')
    await a11yAudit()
  })
})
