import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AvatarGroupHarness, AvatarHarness } from '@ember-joinery/test-support'
import AvatarRtl from 'docs-app/examples/avatar-rtl'

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

module('Example | avatar-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the badge is on the left and the count in Arabic', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><AvatarRtl /></DirectionProvider>
      </template>,
    )
    const [, evilrabbit] = AvatarHarness.findAll()
    const box = evilrabbit!.element.getBoundingClientRect()
    assert.strictEqual(evilrabbit!.badge!.getBoundingClientRect().left, box.left, 'end-0: the left')

    const group = new AvatarGroupHarness()
    assert.strictEqual(group.count, '+٣')
    const [first, second] = group.avatars
    assert.ok(
      first!.element.getBoundingClientRect().left > second!.element.getBoundingClientRect().left,
      'the first avatar is on the right',
    )
    assert.strictEqual(getComputedStyle(first!.element).marginLeft, '-8px', 'and overlaps leftward')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS, { runOnly: ['color-contrast'] })
  })
})
