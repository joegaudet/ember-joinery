import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, IconHarness } from '@ember-joinery/test-support'
import AvatarBadgeIcon from 'docs-app/examples/avatar-badge-icon'

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
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
