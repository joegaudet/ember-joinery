import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CommandHarness } from '@ember-joinery/test-support'
import CommandDemo from 'docs-app/examples/command-demo'

module('Example | command-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a command menu: type to filter, the arrows to move, Enter to choose', async function (assert) {
    await render(<template><CommandDemo /></template>)
    const command = new CommandHarness()
    assert.strictEqual(command.input.placeholder, 'Type a command or search...')
    assert.deepEqual(command.headings, ['Suggestions', 'Settings'])
    assert.deepEqual(command.itemValues, [
      'Calendar',
      'Search Emoji',
      'Calculator',
      'Profile ⌘P',
      'Billing ⌘B',
      'Settings ⌘S',
    ])
    assert.true(command.isDisabled('Calculator'))
    assert.strictEqual(command.selected, 'Calendar')
    assert.strictEqual(command.status, '6 results')
    await a11yAudit()

    await command.press('ArrowDown')
    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'Profile ⌘P', 'past the disabled Calculator')

    await command.search('set')
    assert.deepEqual(command.itemValues, ['Settings ⌘S'])
    assert.deepEqual(command.headings, ['Settings'])
    assert.strictEqual(command.separators.length, 0)
    assert.strictEqual(command.status, '1 result')

    await command.search('nothing')
    assert.dom(command.empty).hasText('No results found.')
    await a11yAudit()
  })
})
