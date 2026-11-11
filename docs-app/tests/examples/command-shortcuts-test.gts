import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CommandDialogHarness } from '@ember-joinery/test-support'
import CommandWithShortcuts from 'docs-app/examples/command-shortcuts'

module('Example | command-shortcuts', function (hooks) {
  setupRenderingTest(hooks)

  test('items show their shortcuts', async function (assert) {
    await render(<template><CommandWithShortcuts /></template>)
    await new ButtonHarness().click()
    const palette = new CommandDialogHarness()
    const command = palette.command
    assert.deepEqual(command.headings, ['Settings'])
    assert.deepEqual(command.texts, ['Profile ⌘P', 'Billing ⌘B', 'Settings ⌘S'])
    for (const item of command.items) {
      assert.dom('[data-slot="command-shortcut"]', item).exists()
    }
    await command.press('End')
    assert.strictEqual(command.selected, 'Settings ⌘S')
    await a11yAudit()
  })
})
