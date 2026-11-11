import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, DropdownMenuHarness } from '@ember-joinery/test-support'
import ButtonGroupDemo from 'docs-app/examples/button-group-demo'

const style = (element: Element) => getComputedStyle(element)

module('Example | button-group-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a mail toolbar: three groups, the last joining a button to its menu', async function (assert) {
    await render(<template><ButtonGroupDemo /></template>)
    const toolbar = new ButtonGroupHarness()
    assert.strictEqual(toolbar.groups.length, 3)
    assert.strictEqual(style(toolbar.element).columnGap, '8px', 'groups of groups are spaced')
    const [snooze, more] = toolbar.groups[2]!.buttons
    assert.strictEqual(snooze!.label, 'Snooze')
    assert.strictEqual(more!.label, 'More Options')

    // The menu's trigger is inside the menu's root, which the group's rules reach through.
    assert.strictEqual(style(snooze!.element).borderTopRightRadius, '0px', 'joined to the menu')
    assert.strictEqual(style(snooze!.element).borderBottomRightRadius, '0px')
    assert.strictEqual(style(more!.element).borderTopLeftRadius, '0px')
    assert.strictEqual(style(more!.element).borderLeftWidth, '0px', 'one border between them')
    assert.notStrictEqual(style(more!.element).borderTopRightRadius, '0px', 'the end is rounded')

    const menu = new DropdownMenuHarness()
    assert.strictEqual(menu.trigger, more!.element)
    await menu.open()
    assert.strictEqual(menu.align, 'end')
    assert.deepEqual(menu.items, [
      'Mark as Read',
      'Archive',
      'Snooze',
      'Add to Calendar',
      'Add to List',
      'Label As...',
      'Trash',
    ])
    assert.strictEqual(menu.variant('Trash'), 'destructive')

    const label = menu.sub('Label As...')
    await label.open()
    assert.deepEqual(label.items, ['Personal', 'Work', 'Other'])
    assert.true(label.isChecked('Personal'))
    await a11yAudit()

    await label.select('Work')
    await menu.open()
    await menu.sub('Label As...').open()
    assert.true(menu.sub('Label As...').isChecked('Work'))
    await a11yAudit()
  })
})
