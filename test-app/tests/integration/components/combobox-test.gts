import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { array, get } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Combobox } from '@ember-joinery/ember'
import { ComboboxHarness, hover, pressKey } from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

const rect = (element: Element) => element.getBoundingClientRect()

function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.setProperty('color', `var(${name})`)
  document.body.append(probe)
  const color = getComputedStyle(probe).color
  probe.remove()
  return color
}

function finishAnimations(element: Element) {
  for (const animation of element.getAnimations({ subtree: true })) animation.finish()
}

const frameworks = ['Next.js', 'SvelteKit', 'Nuxt.js', 'Remix', 'Astro']

module('Integration | components | combobox', function (hooks) {
  setupRenderingTest(hooks)

  test('the input renders upstream’s input group, with its chevron button', async function (assert) {
    await render(
      <template>
        <Combobox @name="framework" @items={{frameworks}} as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Content>
            <c.Empty>No items found.</c.Empty>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness('framework')
    const group = combobox.part('input-group')
    assert
      .dom(group)
      .hasClass('jn-input-group')
      .hasClass('jn-combobox-input')
      .hasAttribute('data-slot', 'input-group')
      .hasAttribute('role', 'group')
    assert
      .dom(combobox.input)
      .hasClass('jn-input')
      .hasClass('jn-input-group-input')
      .hasAttribute('data-slot', 'input-group-control')
      .hasAttribute('placeholder', 'Select a framework')
    assert
      .dom(combobox.trigger)
      .hasClass('jn-input-group-button')
      .hasClass('jn-combobox-trigger')
      .hasClass('jn-button-variant-ghost')
      .hasAttribute('data-slot', 'input-group-button')
      .hasAttribute('data-size', 'icon-xs')
      .hasAttribute('aria-label', 'Show options', 'named, though upstream’s isn’t')
      .hasAttribute('tabindex', '-1')
    assert
      .dom('[data-test-jn-part="trigger-icon"]', combobox.trigger)
      .hasClass('jn-combobox-trigger-icon')
    assert.strictEqual(combobox.clearButton, null, 'no clear button without @showClear')

    const style = getComputedStyle(group)
    assert.strictEqual(style.height, '32px', 'h-8')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.borderTopWidth, '1px')
    assert.strictEqual(style.borderTopColor, token('--input'))
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(getComputedStyle(combobox.trigger!).width, '24px', 'size-6')
    assert.strictEqual(
      getComputedStyle(combobox.input!).borderTopWidth,
      '0px',
      'the input has no border of its own',
    )
    await a11yAudit()
  })

  test('the popup and its items are styled, below the input, as wide as the group', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 300px; width: 240px">
          <Combobox @items={{frameworks}} @defaultValue="Remix" as |c|>
            <c.Input placeholder="Select a framework" />
            <c.Content>
              <c.Empty>No items found.</c.Empty>
              <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
            </c.Content>
          </Combobox>
        </div>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.open()
    const content = combobox.content!
    finishAnimations(content)
    assert
      .dom(content)
      .hasClass('jn-combobox-content')
      .hasAttribute('data-slot', 'combobox-content')
      .hasAttribute('data-chips', 'false')
      .hasAttribute('data-side', 'bottom')
      .hasAttribute('data-align', 'start')
      .doesNotHaveClass('jn-menu-translucent')
    const style = getComputedStyle(content)
    assert.strictEqual(style.backgroundColor, token('--popover'), 'bg-popover')
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(
      style.maxHeight,
      style.getPropertyValue('--jn-anchor-available-height'),
      'max-h-(--available-height), which beats the sheet’s max-h-72 as upstream’s cn() does',
    )

    const input = rect(combobox.input!)
    const group = rect(combobox.part('input-group'))
    const popup = rect(content)
    assert.true(Math.abs(popup.left - input.left) <= 1, 'at the input’s start')
    assert.true(popup.top > group.bottom, 'below the group')
    assert.true(
      popup.width >= group.width - 2,
      `as wide as the group (${popup.width}, ${group.width})`,
    )

    assert
      .dom(combobox.list)
      .hasClass('jn-combobox-list')
      .hasAttribute('data-slot', 'combobox-list')
    const item = combobox.item('Astro')
    assert.dom(item).hasClass('jn-combobox-item').hasAttribute('data-slot', 'combobox-item')
    const itemStyle = getComputedStyle(item)
    assert.strictEqual(itemStyle.paddingTop, '4px', 'py-1')
    assert.strictEqual(itemStyle.paddingInlineStart, '6px', 'ps-1.5')
    assert.strictEqual(itemStyle.paddingInlineEnd, '32px', 'pe-8')
    assert.strictEqual(px(itemStyle.fontSize), 14, 'text-sm')
    assert.strictEqual(
      getComputedStyle(combobox.item('Remix')).backgroundColor,
      token('--accent'),
      'the highlighted item: data-highlighted:bg-accent',
    )
    const indicator = combobox.item('Remix').querySelector('.jn-combobox-item-indicator')!
    assert.strictEqual(getComputedStyle(indicator).position, 'absolute')
    assert.dom('svg', indicator).exists('a check on the chosen item')
    assert.dom('.jn-combobox-item-indicator', item).doesNotExist()
    const empty = combobox.part('empty')
    assert.dom(empty).hasClass('jn-combobox-empty')
    assert.strictEqual(getComputedStyle(empty).display, 'none', 'hidden while there are items')

    await combobox.deleteBackward(5)
    await combobox.type('zz')
    assert.true(combobox.isEmpty)
    assert.strictEqual(getComputedStyle(empty).display, 'flex', 'group-data-empty:flex')
    assert.strictEqual(combobox.emptyText, 'No items found.')
    await a11yAudit()
  })

  test('@showClear: the clear button takes the chevron’s place while there is a value', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} @defaultValue="Next.js" as |c|>
          <c.Input placeholder="Select a framework" @showClear={{true}} />
          <c.Content><c.List as |item|><c.Item
                @value={{item}}
              >{{item}}</c.Item></c.List></c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    assert
      .dom(combobox.clearButton)
      .hasClass('jn-combobox-clear')
      .hasAttribute('data-slot', 'combobox-clear')
      .hasAttribute('aria-label', 'Clear')
    assert.strictEqual(getComputedStyle(combobox.trigger!).display, 'none', 'the chevron hides')
    await combobox.clear()
    assert.strictEqual(combobox.inputValue, '')
    assert.strictEqual(combobox.clearButton, null)
    assert.notStrictEqual(getComputedStyle(combobox.trigger!).display, 'none', 'and comes back')
    await a11yAudit()
  })

  test('@disabled and aria-invalid', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} @name="off" as |c|>
          <c.Input placeholder="Select a framework" @disabled={{true}} />
          <c.Content><c.List as |item|><c.Item
                @value={{item}}
              >{{item}}</c.Item></c.List></c.Content>
        </Combobox>
        <Combobox @items={{frameworks}} @name="bad" as |c|>
          <c.Input placeholder="Select a framework" aria-invalid="true" />
          <c.Content><c.List as |item|><c.Item
                @value={{item}}
              >{{item}}</c.Item></c.List></c.Content>
        </Combobox>
      </template>,
    )
    const off = new ComboboxHarness('off')
    assert.dom(off.input).isDisabled()
    assert.dom(off.trigger).isDisabled()
    assert.strictEqual(
      getComputedStyle(off.part('input-group')).opacity,
      '0.5',
      'has-disabled:opacity-50',
    )
    const bad = new ComboboxHarness('bad')
    assert.true(bad.isInvalid)
    assert.strictEqual(
      getComputedStyle(bad.part('input-group')).borderTopColor,
      token('--destructive'),
      'the group draws the destructive border',
    )
    await a11yAudit()
  })

  test('chips: a field of chips, each with its remove button, and the list as wide as the field', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 300px; width: 320px">
          <Combobox
            @items={{frameworks}}
            @multiple={{true}}
            @defaultValue={{array "Next.js"}}
            as |c|
          >
            <c.Chips>
              <c.Value as |values|>
                {{#each values as |value|}}<c.Chip @value={{value}}>{{value}}</c.Chip>{{/each}}
                <c.ChipsInput aria-label="Frameworks" />
              </c.Value>
            </c.Chips>
            <c.Content @anchor={{c.chipsElement}}>
              <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
            </c.Content>
          </Combobox>
        </div>
      </template>,
    )
    const combobox = new ComboboxHarness()
    const chips = combobox.part('chips')
    assert.dom(chips).hasClass('jn-combobox-chips').hasAttribute('data-slot', 'combobox-chips')
    const chip = combobox.chip('Next.js')
    assert.dom(chip).hasClass('jn-combobox-chip').hasAttribute('data-slot', 'combobox-chip')
    const remove = chip.querySelector('[data-test-jn-part="chip-remove"]')!
    assert
      .dom(remove)
      .hasClass('jn-combobox-chip-remove')
      .hasClass('jn-button-size-icon-xs')
      .hasAttribute('aria-label', 'Remove')
    assert
      .dom(combobox.input)
      .hasClass('jn-combobox-chip-input')
      .hasAttribute('data-slot', 'combobox-chip-input')
    assert.strictEqual(getComputedStyle(chips).display, 'flex')
    assert.strictEqual(getComputedStyle(chips).minHeight, '32px', 'min-h-8')
    assert.strictEqual(getComputedStyle(chip).backgroundColor, token('--muted'), 'bg-muted')
    assert.strictEqual(getComputedStyle(chip).height, '21px', 'h-[calc(--spacing(5.25))]')

    await combobox.open()
    const content = combobox.content!
    finishAnimations(content)
    assert.dom(content).hasAttribute('data-chips', 'true')
    assert.true(Math.abs(rect(content).width - rect(chips).width) <= 1, 'as wide as the chips')
    await combobox.pressItem('Astro')
    assert.deepEqual(combobox.chips, ['Next.js', 'Astro'])
    await combobox.removeChip('Next.js')
    assert.deepEqual(combobox.chips, ['Astro'])
    await a11yAudit()
  })

  test('the input in the popup, behind a Button of your own', async function (assert) {
    const countries = [
      { code: '', label: 'Select country' },
      { code: 'ar', label: 'Argentina' },
      { code: 'br', label: 'Brazil' },
    ]
    await render(
      <template>
        <Combobox @items={{countries}} @defaultValue={{get countries 0}} as |c|>
          <Button @variant="outline" aria-label="Country" {{c.trigger}}>
            <c.Value />
            <c.TriggerIcon />
          </Button>
          <c.Content>
            <c.Input @showTrigger={{false}} placeholder="Search" />
            <c.List as |item|><c.Item @value={{item}}>{{get item "label"}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    assert.dom(combobox.trigger).hasText('Select country').hasAttribute('data-slot', 'button')
    await combobox.pressTrigger()
    finishAnimations(combobox.content!)
    assert.dom(combobox.input).isFocused()
    const group = combobox.part('input-group')
    assert.strictEqual(getComputedStyle(group).marginTop, '4px', 'm-1, in the popup')
    assert.strictEqual(getComputedStyle(group).marginBottom, '0px', 'mb-0')
    assert.dom('[data-slot="input-group-button"]', group).doesNotExist('no chevron inside')
    await combobox.type('arg')
    await pressKey('ArrowDown')
    await pressKey('Enter')
    assert.dom(combobox.trigger).hasText('Argentina')
    await a11yAudit()
  })

  test('right to left: the check mark and the chips flip', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Combobox @items={{frameworks}} @defaultValue="Remix" as |c|>
            <c.Input placeholder="اختر" />
            <c.Content><c.List as |item|><c.Item
                  @value={{item}}
                >{{item}}</c.Item></c.List></c.Content>
          </Combobox>
        </DirectionProvider>
      </template>,
    )
    const combobox = new ComboboxHarness()
    const group = rect(combobox.part('input-group'))
    assert.true(
      rect(combobox.trigger!).left < group.left + group.width / 2,
      'the chevron is at the left',
    )
    await combobox.open()
    const item = combobox.item('Remix')
    const indicator = item.querySelector('.jn-combobox-item-indicator')!
    assert.true(
      rect(indicator).left < rect(item).left + rect(item).width / 2,
      'the check is at the left',
    )
    await hover(combobox.item('Astro'))
    assert.strictEqual(combobox.highlighted, 'Astro')
    await a11yAudit()
  })
})
