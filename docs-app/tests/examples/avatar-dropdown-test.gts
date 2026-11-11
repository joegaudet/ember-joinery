import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, ButtonHarness, DropdownMenuHarness } from '@ember-joinery/test-support'
import AvatarDropdown from 'docs-app/examples/avatar-dropdown'

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

module('Example | avatar-dropdown', function (hooks) {
  setupRenderingTest(hooks)

  test('a round ghost button with an avatar opens a menu with a destructive Log out', async function (assert) {
    // render() waits for the image to load, or to fail where there is no network.
    await render(<template><AvatarDropdown /></template>)
    const menu = new DropdownMenuHarness()
    const button = new ButtonHarness()
    assert.strictEqual(menu.trigger, button.element, 'the button is the trigger')
    assert.strictEqual(button.variant, 'ghost')
    assert.strictEqual(button.size, 'icon')
    assert.dom(button.element).hasClass('rounded-full')
    const avatar = button.find(AvatarHarness)
    assert.true(avatar.isLoaded || avatar.isError, 'the image has loaded or failed')
    // The avatar names the button (the audit's button-name rule checks it has one).
    assert.strictEqual(avatar.label, avatar.isLoaded ? 'shadcn' : 'CN')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)

    await menu.open()
    assert.true(menu.isShown)
    assert.strictEqual(getComputedStyle(menu.content!).width, '128px', 'w-32')
    assert.deepEqual(menu.items, ['Profile', 'Billing', 'Settings', 'Log out'])
    assert.strictEqual(menu.separators, 1)
    assert.strictEqual(menu.variant('Log out'), 'destructive')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)

    await menu.select('Profile')
    assert.false(menu.isOpen, 'choosing an item closes it')
  })
})
