import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness } from '@ember-joinery/test-support'
import CheckboxIndeterminate from 'docs-app/examples/checkbox-indeterminate'

const ITEMS = ['hard-disks', 'external-disks', 'cds-dvds', 'connected-servers']

module('Example | checkbox-indeterminate', function (hooks) {
  setupRenderingTest(hooks)

  test('"select all" is indeterminate while only some items are checked', async function (assert) {
    await render(<template><CheckboxIndeterminate /></template>)
    const all = new CheckboxHarness('all')
    const items = ITEMS.map(id => new CheckboxHarness(id))
    const checked = () => items.map(item => item.isChecked)

    assert.strictEqual(all.label, 'Show these items on the desktop')
    assert.true(all.isIndeterminate)
    assert.deepEqual(checked(), [true, true, false, false])
    assert.dom(all.indicator!.querySelector('path')).hasAttribute('d', 'M5 12h14', 'a minus')

    await all.click()
    assert.true(all.isChecked, 'a click on it checks everything')
    assert.deepEqual(checked(), [true, true, true, true])

    await all.click()
    assert.strictEqual(all.state, 'unchecked')
    assert.deepEqual(checked(), [false, false, false, false])

    await items[2]!.check()
    assert.true(all.isIndeterminate, 'one checked item makes it indeterminate again')
    assert.strictEqual(items[2]!.label, 'CDs, DVDs, and iPods')
    for (const item of [items[0]!, items[1]!, items[3]!]) await item.check()
    assert.true(all.isChecked, 'and every item checks it')
    await a11yAudit()
  })
})
