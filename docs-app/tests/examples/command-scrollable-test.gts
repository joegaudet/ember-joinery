import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CommandDialogHarness } from '@ember-joinery/test-support'
import CommandManyItems from 'docs-app/examples/command-scrollable'

module('Example | command-scrollable', function (hooks) {
  setupRenderingTest(hooks)

  test('a long list scrolls, and the selection stays in view', async function (assert) {
    await render(<template><CommandManyItems /></template>)
    await new ButtonHarness().click()
    const command = new CommandDialogHarness().command
    assert.deepEqual(command.headings, ['Navigation', 'Actions', 'View', 'Account', 'Tools'])
    assert.strictEqual(command.status, '23 results')
    const list = command.list
    assert.true(list.scrollHeight > list.clientHeight, 'the list scrolls')
    assert.strictEqual(list.scrollTop, 0)
    await a11yAudit()

    await command.press('End')
    assert.strictEqual(command.selected, 'Code Editor')
    assert.true(list.scrollTop > 0, 'the last item scrolled into view')
    const item = command.item('Code Editor').getBoundingClientRect()
    const box = list.getBoundingClientRect()
    assert.true(item.bottom <= box.bottom + 1, 'all of it')

    await command.press('Home')
    assert.strictEqual(list.scrollTop, 0, 'and back to the top, heading and all')
    await a11yAudit()
  })
})
