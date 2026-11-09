import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, IconHarness } from '@ember-joinery/test-support'
import AvatarBadgeIcon from 'docs-app/examples/avatar-badge-icon'

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

module('Example | avatar-badge-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('a badge with a plus in it', async function (assert) {
    await render(<template><AvatarBadgeIcon /></template>)
    const avatar = new AvatarHarness()
    assert.dom(avatar.element).hasClass('grayscale')
    assert.strictEqual(avatar.label, avatar.isLoaded ? '@pranathip' : 'PP')
    assert.true(avatar.hasBadge)
    const icon = avatar.find(IconHarness)
    assert.true(icon.isDecorative)
    assert.strictEqual(getComputedStyle(icon.element).width, '8px', 'size-2 in a badge')
    await a11yAudit(BUT_THE_INITIALS)
  })
})
