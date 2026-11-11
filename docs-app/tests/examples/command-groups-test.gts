import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CommandDialogHarness } from '@ember-joinery/test-support'
import CommandWithGroups from 'docs-app/examples/command-groups'

module('Example | command-groups', function (hooks) {
  setupRenderingTest(hooks)

  test('groups, icons and a separator; a search hides the groups it empties', async function (assert) {
    await render(<template><CommandWithGroups /></template>)
    await new ButtonHarness().click()
    const command = new CommandDialogHarness().command
    assert.deepEqual(command.headings, ['Suggestions', 'Settings'])
    assert.strictEqual(command.separators.length, 1)
    assert.deepEqual(command.groupValues('Suggestions'), ['Calendar', 'Search Emoji', 'Calculator'])
    await a11yAudit()

    await command.press('ArrowDown', { altKey: true })
    assert.strictEqual(command.selected, 'Profile ⌘P', 'Alt+↓ jumps to the next group')

    await command.search('bil')
    assert.deepEqual(command.headings, ['Settings'])
    assert.deepEqual(command.itemValues, ['Billing ⌘B'])
    await a11yAudit()
  })
})
