import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, DropdownMenuHarness } from '@ember-joinery/test-support'
import ButtonGroupDropdown from 'docs-app/examples/button-group-dropdown'

const style = (element: Element) => getComputedStyle(element)

module('Example | button-group-dropdown', function (hooks) {
  setupRenderingTest(hooks)

  test('a split button: Follow, and a menu of the rest', async function (assert) {
    await render(<template><ButtonGroupDropdown /></template>)
    const [follow, more] = new ButtonGroupHarness().buttons
    assert.strictEqual(follow!.label, 'Follow')
    assert.strictEqual(style(follow!.element).borderTopRightRadius, '0px', 'joined')
    assert.strictEqual(style(more!.element).borderTopLeftRadius, '0px')
    assert.strictEqual(style(more!.element).borderLeftWidth, '0px')
    assert.strictEqual(style(more!.element).paddingLeft, '8px', 'pl-2!')

    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.strictEqual(style(menu.content!).width, '176px', 'w-44')
    assert.deepEqual(menu.items, [
      'Mute Conversation',
      'Mark as Read',
      'Report Conversation',
      'Block User',
      'Share Conversation',
      'Copy Conversation',
      'Delete Conversation',
    ])
    assert.strictEqual(menu.variant('Delete Conversation'), 'destructive')
    await a11yAudit()

    await menu.select('Block User')
    assert.false(menu.isOpen)
    assert.dom(menu.trigger).isFocused()
    await a11yAudit()
  })
})
