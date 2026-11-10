import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Check, Copy } from 'lucide'
import { ButtonHarness, InputGroupHarness, PopoverHarness } from '@ember-joinery/test-support'
import InputGroupButtonExample from 'docs-app/examples/input-group-button'

type IconElement = [tag: string, attributes: Record<string, string>]

/** The `d` of the first path a lucide icon draws: Copy's and Check's differ there. */
function firstPath(icon: unknown): string {
  const [, , elements] = icon as [string, object, IconElement[]]
  return elements.find(([tag]) => tag === 'path')![1]['d']!
}

module('Example | input-group-button', function (hooks) {
  setupRenderingTest(hooks)

  // A test browser's clipboard needs the page focused and a permission granted, so the copy
  // button writes to one of the test's own.
  let copied: string[] = []
  hooks.beforeEach(function () {
    copied = []
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: async (text: string) => void copied.push(text) },
    })
  })
  hooks.afterEach(function () {
    delete (navigator as { clipboard?: unknown }).clipboard
  })

  test('a copy button, a favourite toggle, a popover on an addon and a search button', async function (assert) {
    await render(<template><InputGroupButtonExample /></template>)
    const [link, secure, search] = InputGroupHarness.findAll()

    // Copy: an icon button that shows a check once it has copied the link.
    assert.strictEqual(link!.placeholder, 'https://x.com/shadcn')
    assert.true((link!.control as HTMLInputElement).readOnly)
    const copy = link!.find(ButtonHarness)
    assert.strictEqual(copy.label, 'Copy')
    assert.strictEqual(copy.size, 'icon-xs')
    const icon = () => copy.element.querySelector('path')!.getAttribute('d')
    assert.strictEqual(icon(), firstPath(Copy))
    await copy.click()
    assert.deepEqual(copied, ['https://x.com/shadcn'])
    assert.strictEqual(icon(), firstPath(Check), 'the check shows once it has copied')

    // The secure group: rounded all the way, an info button that opens a popover, the scheme.
    assert.strictEqual(getComputedStyle(secure!.element).borderTopLeftRadius, '9999px')
    assert.deepEqual(secure!.aligns, ['inline-start', 'inline-end'], "the popover's addon aside")
    assert.strictEqual(secure!.addonText('inline-start'), 'https://')
    assert.strictEqual(secure!.label, 'URL')

    const popover = secure!.find(PopoverHarness)
    assert.strictEqual(
      popover.trigger.getAttribute('data-slot'),
      'input-group-addon',
      'the addon is the trigger',
    )
    assert.strictEqual(popover.trigger.getAttribute('data-align'), 'inline-start')
    const info = popover.find(ButtonHarness)
    assert.strictEqual(info.label, 'Info')
    assert.strictEqual(info.variant, 'secondary')
    assert.false(popover.isOpen)
    await info.click()
    assert.true(popover.isOpen, 'a click on its button opens it')
    assert.strictEqual(
      popover.text,
      'Your connection is not secure. You should not enter any sensitive information on this site.',
    )
    assert.strictEqual(popover.align, 'start')
    await a11yAudit()
    await popover.pressEscape()
    assert.false(popover.isOpen)

    const favorite = secure!.findAll(ButtonHarness).find(button => button.label === 'Favorite')!
    const star = () => favorite.element.querySelector('svg')!
    assert.strictEqual(star().getAttribute('data-favorite'), 'false')
    await favorite.click()
    assert.strictEqual(star().getAttribute('data-favorite'), 'true')
    assert.notStrictEqual(getComputedStyle(star()).fill, 'none', 'a favourite star is filled')
    await favorite.click()
    assert.strictEqual(star().getAttribute('data-favorite'), 'false')
    assert.strictEqual(getComputedStyle(star()).fill, 'none')

    // Search: a text button at the end.
    assert.strictEqual(search!.placeholder, 'Type to search...')
    const go = search!.find(ButtonHarness)
    assert.strictEqual(go.label, 'Search')
    assert.strictEqual(go.variant, 'secondary')
    await a11yAudit()
  })
})
