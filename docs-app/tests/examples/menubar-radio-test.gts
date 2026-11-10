import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MenubarHarness } from '@ember-joinery/test-support'
import MenubarRadio from 'docs-app/examples/menubar-radio'

module('Example | menubar-radio', function (hooks) {
  setupRenderingTest(hooks)

  test('a radio group in each menu: choosing one checks it', async function (assert) {
    await render(<template><MenubarRadio /></template>)
    const menubar = new MenubarHarness()
    const profiles = menubar.menu('Profiles')
    await profiles.open()
    assert.strictEqual(profiles.role('Andy'), 'menuitemradio')
    assert.true(profiles.isChecked('Benoit'))
    await a11yAudit()
    await profiles.select('Luis')
    assert.false(profiles.isOpen)
    await profiles.open()
    assert.true(profiles.isChecked('Luis'))
    assert.false(profiles.isChecked('Benoit'))

    const theme = menubar.menu('Theme')
    await theme.hoverTrigger()
    assert.true(theme.isChecked('System'))
    await theme.select('Dark')
    await theme.open()
    assert.true(theme.isChecked('Dark'))
    await a11yAudit()
  })
})
