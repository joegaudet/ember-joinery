import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  AvatarHarness,
  ButtonHarness,
  DropdownMenuHarness,
  IconHarness,
} from '@ember-joinery/test-support'
import DropdownMenuAvatar from 'docs-app/examples/dropdown-menu-avatar'

/**
 * Upstream draws the initials `--muted-foreground` on `--muted`, 4.34:1 in the default theme,
 * under the 4.5:1 WCAG AA asks of their 14px text (the Avatar page's Accessibility notes say
 * how an app can darken it). So the audit runs every rule but colour contrast over the whole
 * example, then colour contrast over all of it but the initials.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
  runOnly: ['color-contrast'],
}

module('Example | dropdown-menu-avatar', function (hooks) {
  setupRenderingTest(hooks)

  test('an avatar opens an account menu lined up with its end', async function (assert) {
    // render() waits for the image to load, or to fail where there is no network.
    await render(<template><DropdownMenuAvatar /></template>)
    const menu = new DropdownMenuHarness()
    const button = new ButtonHarness()
    assert.strictEqual(menu.trigger, button.element, 'the button is the trigger')
    assert.strictEqual(button.variant, 'ghost')
    assert.strictEqual(button.size, 'icon')
    assert.dom(button.element).hasClass('rounded-full')
    const avatar = button.find(AvatarHarness)
    // The avatar names the button (the audit's button-name rule checks it has one).
    assert.strictEqual(avatar.label, avatar.isLoaded ? 'shadcn' : 'LR')

    await menu.openWithKeyboard()
    assert.true(menu.isShown)
    assert.strictEqual(menu.align, 'end')
    assert.deepEqual(menu.items, ['Account', 'Billing', 'Notifications', 'Sign Out'])
    assert.strictEqual(menu.separators, 1)
    assert.strictEqual(menu.highlighted, 'Account', 'the keyboard starts on the first item')
    for (const label of menu.items) {
      const icon = new IconHarness({ within: menu.item(label) })
      assert.true(icon.isDecorative, `${label}'s icon is decorative`)
    }
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)

    await menu.pressEscape()
    assert.false(menu.isOpen)
    assert.dom(button.element).isFocused('focus goes back to the avatar')
  })
})
