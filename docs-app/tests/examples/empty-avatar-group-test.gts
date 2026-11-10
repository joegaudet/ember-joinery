import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  AvatarHarness,
  ButtonHarness,
  EmptyHarness,
  IconHarness,
} from '@ember-joinery/test-support'
import EmptyAvatarGroup from 'docs-app/examples/empty-avatar-group'

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

module('Example | empty-avatar-group', function (hooks) {
  setupRenderingTest(hooks)

  test('three team avatars, overlapping and in grey, and an invite', async function (assert) {
    await render(<template><EmptyAvatarGroup /></template>)
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, 'No Team Members')
    assert.strictEqual(empty.description, 'Invite your team to collaborate on this project.')

    const avatars = empty.findAll(AvatarHarness)
    assert.deepEqual(
      avatars.map(avatar => avatar.label),
      avatars.map((avatar, index) =>
        avatar.isLoaded
          ? ['@shadcn', '@maxleiter', '@evilrabbit'][index]
          : ['CN', 'LR', 'ER'][index],
      ),
      'each named by its image, or its initials if that fails',
    )
    assert.strictEqual(avatars.length, 3)
    for (const avatar of avatars) {
      const style = getComputedStyle(avatar.element)
      assert.strictEqual(style.width, '48px', '*:data-[slot=avatar]:size-12')
      assert.strictEqual(style.filter, 'grayscale(1)', '*:data-[slot=avatar]:grayscale')
      assert.notStrictEqual(style.boxShadow, 'none', '*:data-[slot=avatar]:ring-2')
    }
    assert.strictEqual(
      getComputedStyle(avatars[0]!.element).marginInlineEnd,
      '-8px',
      '-space-x-2: they overlap',
    )

    const invite = empty.find(ButtonHarness)
    assert.strictEqual(invite.label, 'Invite Members')
    assert.strictEqual(invite.size, 'sm')
    assert.true(invite.find(IconHarness).isDecorative)
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
