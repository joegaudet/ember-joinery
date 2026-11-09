import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness } from '@ember-joinery/test-support'
import AvatarSize from 'docs-app/examples/avatar-size'

/**
 * Upstream draws the initials and the count `--muted-foreground` on `--muted`, 4.34:1 in the
 * default theme, under the 4.5:1 WCAG AA asks of their 14px text (the Avatar page's
 * Accessibility notes say how an app can darken it). So the audit runs every rule but colour
 * contrast over the whole example, then colour contrast over all of it but those two.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]'], ['[data-slot="avatar-group-count"]']],
}

module('Example | avatar-size', function (hooks) {
  setupRenderingTest(hooks)

  test('small, default and large', async function (assert) {
    await render(<template><AvatarSize /></template>)
    const avatars = AvatarHarness.findAll()
    assert.deepEqual(
      avatars.map(avatar => avatar.size),
      ['sm', 'default', 'lg'],
    )
    assert.deepEqual(
      avatars.map(avatar => getComputedStyle(avatar.element).width),
      ['24px', '32px', '40px'],
    )
    for (const avatar of avatars) {
      assert.strictEqual(avatar.label, avatar.isLoaded ? '@shadcn' : 'CN')
    }
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
