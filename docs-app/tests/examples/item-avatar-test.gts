import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, ButtonHarness, ItemHarness } from '@ember-joinery/test-support'
import ItemAvatar from 'docs-app/examples/item-avatar'

/**
 * The audit, but for the contrast of the initials, which show where an image fails: upstream
 * draws them `--muted-foreground` on `--muted`, 4.34:1 in the default theme, under the 4.5:1
 * WCAG AA asks of their 14px text (the Avatar page's Accessibility notes say how an app can
 * darken it). Everything around them is audited.
 */
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
}

module('Example | item-avatar', function (hooks) {
  setupRenderingTest(hooks)

  test('a person with an invite button, and a team of avatars', async function (assert) {
    await render(<template><ItemAvatar /></template>)
    const [person, team] = ItemHarness.findAll()

    assert.strictEqual(person!.title, 'Evil Rabbit')
    assert.strictEqual(person!.description, 'Last seen 5 months ago')
    const avatar = person!.find(AvatarHarness)
    assert.strictEqual(getComputedStyle(avatar.element).width, '40px', 'size-10 on the avatar')
    assert.strictEqual(avatar.label, avatar.isLoaded ? '@evilrabbit' : 'ER')
    const invite = person!.find(ButtonHarness)
    assert.strictEqual(invite.label, 'Invite')
    assert.strictEqual(invite.size, 'icon-sm')

    assert.strictEqual(team!.title, 'No Team Members')
    const members = team!.findAll(AvatarHarness)
    assert.strictEqual(members.length, 3)
    for (const member of members) {
      assert.true(member.isLoaded || member.isError)
      assert.strictEqual(
        getComputedStyle(member.element).filter,
        'grayscale(1)',
        "in grey, from its wrapper's *:data-[slot=avatar]:grayscale",
      )
    }
    assert.strictEqual(team!.find(ButtonHarness).label, 'Invite')
    await a11yAudit(BUT_THE_INITIALS)
  })
})
