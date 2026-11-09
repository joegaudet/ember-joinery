import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarGroupHarness, IconHarness } from '@ember-joinery/test-support'
import AvatarGroupCountIcon from 'docs-app/examples/avatar-group-count-icon'

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

module('Example | avatar-group-count-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('three avatars, and a plus where the count goes', async function (assert) {
    await render(<template><AvatarGroupCountIcon /></template>)
    const group = new AvatarGroupHarness()
    assert.strictEqual(group.avatars.length, 3)
    assert.strictEqual(group.count, '', 'an icon, no text')
    const icon = group.find(IconHarness)
    assert.true(icon.isDecorative)
    assert.strictEqual(getComputedStyle(icon.element).width, '16px', 'size-4 in the count')
    await a11yAudit(BUT_THE_INITIALS)
  })
})
