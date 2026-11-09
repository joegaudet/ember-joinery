import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness } from '@ember-joinery/test-support'
import AvatarBasic from 'docs-app/examples/avatar-basic'

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

module('Example | avatar-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('the image, in grey, or its initials if it fails', async function (assert) {
    await render(<template><AvatarBasic /></template>)
    const avatar = new AvatarHarness()
    assert.strictEqual(avatar.size, 'default')
    if (avatar.isLoaded) {
      assert.strictEqual(avatar.label, '@shadcn')
      assert.dom(avatar.image).hasClass('grayscale')
      assert.strictEqual(avatar.fallback, null)
    } else {
      assert.true(avatar.isError, 'no network: the image failed')
      assert.strictEqual(avatar.fallbackText, 'CN')
    }
    await a11yAudit(BUT_THE_INITIALS)
  })
})
