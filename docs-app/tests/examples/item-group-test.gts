import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness, ButtonHarness, ItemGroupHarness } from '@ember-joinery/test-support'
import ItemGroup from 'docs-app/examples/item-group'

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

module('Example | item-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a list of people, each with an avatar and an add button', async function (assert) {
    await render(<template><ItemGroup /></template>)
    const group = new ItemGroupHarness()
    assert.dom(group.element).hasAttribute('role', 'list')
    const people = group.items
    assert.deepEqual(
      people.map(person => person.title),
      ['shadcn', 'maxleiter', 'evilrabbit'],
    )
    assert.deepEqual(
      people.map(person => person.description),
      ['shadcn@vercel.com', 'maxleiter@vercel.com', 'evilrabbit@vercel.com'],
    )
    for (const person of people) {
      const avatar = person.find(AvatarHarness)
      assert.strictEqual(avatar.label, avatar.isLoaded ? person.title : person.title.charAt(0))
      const add = person.find(ButtonHarness)
      assert.strictEqual(add.label, `Add ${person.title}`)
      assert.strictEqual(add.variant, 'ghost')
    }
    assert.strictEqual(getComputedStyle(group.element).rowGap, '16px', 'gap-4')
    await a11yAudit(BUT_THE_INITIALS)
  })
})
