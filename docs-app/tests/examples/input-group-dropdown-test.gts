import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DropdownMenuHarness, InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupDropdown from 'docs-app/examples/input-group-dropdown'

/** The addon a menu's trigger sits in: the menu goes around it, so it is the menu's part. */
const addonOf = (menu: DropdownMenuHarness) =>
  menu.trigger.closest<HTMLElement>('[data-slot="input-group-addon"]')!

module('Example | input-group-dropdown', function (hooks) {
  setupRenderingTest(hooks)

  test('an inline-end button in each group opens a menu', async function (assert) {
    await render(<template><InputGroupDropdown /></template>)
    const [file, search] = InputGroupHarness.findAll()
    assert.strictEqual(file!.placeholder, 'Enter file name')
    assert.strictEqual(search!.placeholder, 'Enter search query')
    const more = file!.find(DropdownMenuHarness)
    const searchIn = search!.find(DropdownMenuHarness)

    const moreButton = new ButtonHarness({ within: addonOf(more) })
    assert.strictEqual(more.trigger, moreButton.element, "the addon's button is the trigger")
    assert.strictEqual(moreButton.label, 'More')
    assert.strictEqual(moreButton.variant, 'ghost')
    assert.strictEqual(moreButton.size, 'icon-xs')
    assert.strictEqual(addonOf(more).getAttribute('data-align'), 'inline-end')
    assert.strictEqual(
      getComputedStyle(addonOf(more)).marginInlineEnd,
      '-4.8px',
      'the addon pulls its button into its padding, as upstream has-[>button] does',
    )
    assert.strictEqual(
      getComputedStyle(addonOf(more)).order,
      '9999',
      'order-last: after the input, though the menu around it comes after it too',
    )

    const searchButton = new ButtonHarness({ within: addonOf(searchIn) })
    assert.strictEqual(searchIn.trigger, searchButton.element)
    assert.strictEqual(searchButton.label, 'Search In...')
    assert.strictEqual(getComputedStyle(searchButton.element).paddingRight, '6px', 'pr-1.5!')
    assert.strictEqual(getComputedStyle(search!.element).borderTopLeftRadius, '16px')
    await a11yAudit()

    await more.open()
    assert.strictEqual(more.align, 'end')
    assert.deepEqual(more.items, ['Settings', 'Copy path', 'Open location'])
    await a11yAudit()
    await more.select('Copy path')
    assert.false(more.isOpen)

    await searchIn.openWithKeyboard()
    assert.deepEqual(searchIn.items, ['Documentation', 'Blog Posts', 'Changelog'])
    assert.strictEqual(searchIn.highlighted, 'Documentation')
    assert.strictEqual(
      getComputedStyle(searchIn.content!).getPropertyValue('--radius').trim(),
      '.95rem',
      '[--radius:0.95rem], as Tailwind writes it',
    )
    await a11yAudit()
    await searchIn.pressEscape()
    assert.dom(searchButton.element).isFocused()
  })
})
