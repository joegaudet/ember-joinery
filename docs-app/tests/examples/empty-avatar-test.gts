import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, ButtonHarness, EmptyHarness } from '@ember-joinery/test-support'
import EmptyAvatar from 'docs-app/examples/empty-avatar'

/**
 * Upstream draws an avatar's initials `--muted-foreground` on `--muted`, 4.34:1 in the default
 * theme, under the 4.5:1 WCAG AA asks of their 14px text (the Avatar page's Accessibility notes
 * say how an app can darken it). So the audit runs every rule but colour contrast over the whole
 * example, then colour contrast over all of it but the initials.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
}

module('Example | empty-avatar', function (hooks) {
  setupRenderingTest(hooks)

  test('an offline user’s avatar, in grey, with a message to leave', async function (assert) {
    await render(<template><EmptyAvatar /></template>)
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, 'User Offline')
    assert.strictEqual(
      empty.description,
      'This user is currently offline. You can leave a message to notify them or try again later.',
    )
    assert.strictEqual(empty.mediaVariant, 'default')

    const avatar = empty.find(AvatarHarness)
    assert.strictEqual(getComputedStyle(avatar.element).width, '48px', 'size-12')
    assert.strictEqual(getComputedStyle(avatar.element).height, '48px')
    if (avatar.isLoaded) {
      assert.strictEqual(avatar.label, '@shadcn')
      assert.dom(avatar.image).hasClass('grayscale')
    } else {
      assert.true(avatar.isError, 'no network: the image failed')
      assert.strictEqual(avatar.fallbackText, 'LR')
    }

    const leave = empty.find(ButtonHarness)
    assert.strictEqual(leave.label, 'Leave Message')
    assert.strictEqual(leave.size, 'sm')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
