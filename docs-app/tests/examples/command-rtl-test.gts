import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CommandHarness } from '@ember-joinery/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import CommandRtl from 'docs-app/examples/command-rtl'

module('Example | command-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl"><CommandRtl /></DirectionProvider>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(getComputedStyle(command.element).direction, 'rtl')
    assert.deepEqual(command.headings, ['اقتراحات', 'الإعدادات'])
    const icon = command.input.parentElement!.querySelector('svg')!.getBoundingClientRect()
    assert.true(icon.left > command.input.getBoundingClientRect().left, 'the icon is on the right')
    const profile = command.items[3]!
    const shortcut = profile.querySelector('[data-slot="command-shortcut"]')!
    assert.true(
      shortcut.getBoundingClientRect().left <
        profile.querySelector('span')!.getBoundingClientRect().left,
      'the shortcut ends the item, on the left',
    )
    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'البحث عن الرموز التعبيرية')
    await command.search('الإعدادات')
    assert.deepEqual(command.itemValues, ['الإعدادات ⌘S'])
    await a11yAudit()
  })
})
