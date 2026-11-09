import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarGroupHarness, AvatarHarness } from '@ember-joinery/test-support'
import AvatarDemo from 'docs-app/examples/avatar-demo'

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

module('Example | avatar-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('an avatar, one with a badge, and a group with a count', async function (assert) {
    // render() waits for every image to load, or to fail where there is no network.
    await render(<template><AvatarDemo /></template>)
    const [shadcn, evilrabbit] = AvatarHarness.findAll()
    for (const avatar of AvatarHarness.findAll()) {
      assert.true(avatar.isLoaded || avatar.isError, 'each image has loaded or failed')
    }
    assert.strictEqual(shadcn!.label, shadcn!.isLoaded ? '@shadcn' : 'CN')
    assert.false(shadcn!.hasBadge)
    assert.strictEqual(evilrabbit!.label, evilrabbit!.isLoaded ? '@evilrabbit' : 'ER')
    assert.true(evilrabbit!.hasBadge, 'a status dot')
    assert.dom(evilrabbit!.badge).hasClass('bg-green-600')

    const group = new AvatarGroupHarness()
    assert.dom(group.element).hasClass('grayscale')
    assert.deepEqual(
      group.avatars.map(avatar => (avatar.isLoaded ? avatar.label : avatar.fallbackText)),
      group.avatars.map((avatar, index) =>
        avatar.isLoaded
          ? ['@shadcn', '@maxleiter', '@evilrabbit'][index]
          : ['CN', 'LR', 'ER'][index],
      ),
    )
    assert.strictEqual(group.count, '+3')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
