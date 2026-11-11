import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness } from '@ember-joinery/test-support'
import ContextMenuRadio from 'docs-app/examples/context-menu-radio'

module('Example | context-menu-radio', function (hooks) {
  setupRenderingTest(hooks)

  test('a person and a theme, one of each checked', async function (assert) {
    await render(<template><ContextMenuRadio /></template>)
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.labels, ['People', 'Theme'])
    assert.deepEqual(menu.items, ['Pedro Duarte', 'Colm Tuite', 'Light', 'Dark', 'System'])
    assert.true(menu.isChecked('Pedro Duarte'))
    assert.true(menu.isChecked('Light'))
    await a11yAudit()
    await menu.select('System')
    await menu.open()
    assert.true(menu.isChecked('System'))
    assert.false(menu.isChecked('Light'))
    assert.true(menu.isChecked('Pedro Duarte'), 'the other group is unchanged')
    await a11yAudit()
  })
})
