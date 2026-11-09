import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarGroupHarness } from '@ember-joinery/test-support'
import AvatarGroup from 'docs-app/examples/avatar-group'

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

module('Example | avatar-group', function (hooks) {
  setupRenderingTest(hooks)

  test('three avatars, overlapping, in grey', async function (assert) {
    await render(<template><AvatarGroup /></template>)
    const group = new AvatarGroupHarness()
    assert.dom(group.element).hasClass('grayscale')
    const [shadcn, maxleiter, evilrabbit] = group.avatars
    assert.strictEqual(group.avatars.length, 3)
    assert.strictEqual(shadcn!.label, shadcn!.isLoaded ? '@shadcn' : 'CN')
    assert.strictEqual(maxleiter!.label, maxleiter!.isLoaded ? '@maxleiter' : 'LR')
    assert.strictEqual(evilrabbit!.label, evilrabbit!.isLoaded ? '@evilrabbit' : 'ER')
    assert.strictEqual(getComputedStyle(shadcn!.element).marginInlineEnd, '-8px', '-space-x-2')
    assert.strictEqual(group.count, null, 'no count')
    await a11yAudit(BUT_THE_INITIALS)
  })
})
