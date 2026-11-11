import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  AvatarHarness,
  ButtonHarness,
  DropdownMenuHarness,
  ItemHarness,
} from '@ember-joinery/test-support'
import ItemDropdown from 'docs-app/examples/item-dropdown'

/**
 * Upstream draws the initials `--muted-foreground` on `--muted`, 4.34:1 in the default theme,
 * under the 4.5:1 WCAG AA asks of their 14px text (the Avatar page's Accessibility notes say
 * how an app can darken it). So the audit runs every rule but colour contrast over the whole
 * example, then colour contrast over all of it but the initials.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
  runOnly: ['color-contrast'],
}

module('Example | item-dropdown', function (hooks) {
  setupRenderingTest(hooks)

  test('each person is an item in a menu', async function (assert) {
    await render(<template><ItemDropdown /></template>)
    const menu = new DropdownMenuHarness()
    const button = new ButtonHarness()
    assert.strictEqual(menu.trigger, button.element, 'the button is the trigger')
    assert.strictEqual(button.variant, 'outline')
    assert.strictEqual(button.label, 'Select')

    await menu.open()
    assert.strictEqual(getComputedStyle(menu.content!).width, '192px', 'w-48')
    assert.strictEqual(menu.align, 'end')
    assert.deepEqual(menu.items, [
      'shadcn shadcn@vercel.com',
      'maxleiter maxleiter@vercel.com',
      'evilrabbit evilrabbit@vercel.com',
    ])

    const people = ItemHarness.findAll()
    assert.deepEqual(
      people.map(person => [person.title, person.description, person.size]),
      [
        ['shadcn', 'shadcn@vercel.com', 'xs'],
        ['maxleiter', 'maxleiter@vercel.com', 'xs'],
        ['evilrabbit', 'evilrabbit@vercel.com', 'xs'],
      ],
    )
    for (const person of people) {
      const avatar = person.find(AvatarHarness)
      // render() waited for the image; opening the menu rendered it, so wait for it too.
      assert.true(avatar.isLoaded || avatar.isError || avatar.isLoading)
      assert.strictEqual(getComputedStyle(avatar.element).width, '26px', 'size-[--spacing(6.5)]')
      if (avatar.isLoaded) assert.dom(avatar.image).hasClass('grayscale')
      else assert.strictEqual(avatar.fallbackText, person.title.charAt(0))
    }
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)

    await menu.select('maxleiter maxleiter@vercel.com')
    assert.false(menu.isOpen)
  })
})
