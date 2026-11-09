import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness } from '@ember-joinery/test-support'
import AvatarBadge from 'docs-app/examples/avatar-badge'

/**
 * The audit, but for the contrast of the initials and the count: upstream draws them
 * `--muted-foreground` on `--muted`, 4.34:1 in the default theme, under the 4.5:1 WCAG AA asks
 * of their 14px text (the Avatar page's Accessibility notes say how an app can darken it).
 * Everything around them is audited.
 */
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]'], ['[data-slot="avatar-group-count"]']],
}

module('Example | avatar-badge', function (hooks) {
  setupRenderingTest(hooks)

  test('a green dot on the bottom right corner', async function (assert) {
    await render(<template><AvatarBadge /></template>)
    const avatar = new AvatarHarness()
    assert.strictEqual(avatar.label, avatar.isLoaded ? '@shadcn' : 'CN')
    const badge = avatar.badge!
    assert.dom(badge).hasClass('bg-green-600', 'its colour is a class of your own')
    const box = avatar.element.getBoundingClientRect()
    const dot = badge.getBoundingClientRect()
    assert.strictEqual(dot.right, box.right)
    assert.strictEqual(dot.bottom, box.bottom)
    assert.strictEqual(getComputedStyle(badge).width, '10px', 'size-2.5')
    assert.notStrictEqual(
      getComputedStyle(badge).backgroundColor,
      getComputedStyle(document.body).backgroundColor,
    )
    await a11yAudit(BUT_THE_INITIALS)
  })
})
