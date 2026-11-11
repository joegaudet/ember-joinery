import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Calendar, Circle, Settings, Smile, User, Zap } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Command, CommandDialog, Icon } from '@ember-joinery/ember'
import { CommandDialogHarness, CommandHarness, IconHarness } from '@ember-joinery/test-support'

/** Ends a dialog's entrance animation, so it is measured where it rests. */
function settle(element: Element | null): void {
  for (const animation of element?.getAnimations() ?? []) animation.finish()
}

function transparent(color: string): boolean {
  return color === 'rgba(0, 0, 0, 0)' || color === 'transparent'
}

class Open {
  @tracked open = false
  setOpen = (open: boolean) => (this.open = open)
}

module('Integration | components | command', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's parts, with their classes and data attributes", async function (assert) {
    await render(
      <template>
        <Command @name="demo" class="max-w-sm" as |c|>
          <c.Input placeholder="Type a command or search..." />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Suggestions">
              <c.Item><Icon @icon={{Calendar}} /><span>Calendar</span></c.Item>
              <c.Item @disabled={{true}}><Icon @icon={{Smile}} /><span>Search Emoji</span></c.Item>
            </c.Group>
            <c.Separator />
            <c.Group @heading="Settings">
              <c.Item>
                <Icon @icon={{User}} />
                <span>Profile</span>
                <c.Shortcut>⌘P</c.Shortcut>
              </c.Item>
            </c.Group>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness('demo')
    assert.dom(command.element).hasClass('jn-command').hasClass('max-w-sm', 'yours adds to it')
    assert.dom(command.element).hasAttribute('data-slot', 'command').hasAttribute('cmdk-root', '')

    const wrapper = command.input.closest('[data-slot="command-input-wrapper"]')!
    assert.dom(wrapper).hasClass('jn-command-input-wrapper')
    const group = command.input.parentElement!
    assert
      .dom(group)
      .hasClass('jn-input-group')
      .hasClass('jn-command-input-group')
      .hasClass('group/input-group')
      .hasAttribute('data-slot', 'input-group')
      .hasAttribute('role', 'group')
    assert
      .dom(command.input)
      .hasClass('jn-command-input')
      .hasAttribute('data-slot', 'command-input')
      .hasAttribute('placeholder', 'Type a command or search...')
    const addon = group.querySelector('[data-slot="input-group-addon"]')!
    assert
      .dom(addon)
      .hasClass('jn-input-group-addon')
      .hasClass('jn-input-group-addon-align-inline-start')
      .hasAttribute('data-align', 'inline-start')
    assert.dom('svg', addon).hasClass('jn-command-input-icon').hasClass('lucide')

    assert.dom(command.list).hasClass('jn-command-list').hasAttribute('data-slot', 'command-list')
    for (const element of command.groups) {
      assert.dom(element).hasClass('jn-command-group').hasAttribute('data-slot', 'command-group')
    }
    assert
      .dom(command.separators[0])
      .hasClass('jn-command-separator')
      .hasAttribute('data-slot', 'command-separator')
    for (const item of command.items) {
      assert
        .dom(item)
        .hasClass('jn-command-item')
        .hasClass('group/command-item')
        .hasAttribute('data-slot', 'command-item')
      assert.dom('svg.jn-command-item-indicator', item).exists('each item ends in a check')
    }
    assert.deepEqual(
      command.itemValues,
      ['Calendar', 'Search Emoji', 'Profile ⌘P'],
      'values are their text, its spaces collapsed',
    )
    const shortcut = command.item('Profile ⌘P').querySelector('[data-slot="command-shortcut"]')!
    assert.dom(shortcut).hasClass('jn-command-shortcut').hasText('⌘P')

    await command.search('zzz')
    assert
      .dom(command.empty)
      .hasClass('jn-command-empty')
      .hasAttribute('data-slot', 'command-empty')
    await a11yAudit()
  })

  test('its style sheet styles it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Command class="w-96" as |c|>
          <c.Input placeholder="Type a command or search..." />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Suggestions">
              <c.Item><Icon @icon={{Calendar}} /><span>Calendar</span></c.Item>
              <c.Item @disabled={{true}}><Icon @icon={{Smile}} /><span>Search Emoji</span></c.Item>
            </c.Group>
            <c.Separator />
            <c.Group @heading="Settings">
              <c.Item>
                <Icon @icon={{Settings}} />
                <span>Settings</span>
                <c.Shortcut>⌘S</c.Shortcut>
              </c.Item>
            </c.Group>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    const root = getComputedStyle(command.element)
    assert.strictEqual(root.display, 'flex')
    assert.strictEqual(root.flexDirection, 'column')
    assert.strictEqual(root.overflow, 'hidden')
    assert.strictEqual(root.paddingTop, '4px', 'p-1')
    assert.strictEqual(root.borderTopLeftRadius, '14px', 'rounded-xl!')
    assert.false(transparent(root.backgroundColor), 'bg-popover')

    const wrapper = getComputedStyle(command.input.closest('.jn-command-input-wrapper')!)
    assert.strictEqual(wrapper.paddingTop, '4px', 'p-1')
    assert.strictEqual(wrapper.paddingBottom, '0px', 'pb-0')
    const group = command.input.parentElement!
    const groupStyle = getComputedStyle(group)
    assert.strictEqual(groupStyle.display, 'flex')
    assert.strictEqual(groupStyle.height, '32px', 'h-8!')
    assert.strictEqual(groupStyle.borderTopLeftRadius, '10px', 'rounded-lg!')
    assert.notOk(/\d+px [1-9]/.test(groupStyle.boxShadow), 'shadow-none!: every shadow is empty')
    assert.strictEqual(getComputedStyle(command.input).fontSize, '14px', 'text-sm')
    const addon = group.querySelector<HTMLElement>('.jn-input-group-addon')!
    assert.strictEqual(getComputedStyle(addon).paddingLeft, '8px', 'ps-2!')
    assert.strictEqual(getComputedStyle(addon).order, '-9999', 'order-first')
    const icon = addon.querySelector('svg')!
    assert.strictEqual(getComputedStyle(icon).width, '16px', 'size-4')
    assert.strictEqual(getComputedStyle(icon).opacity, '0.5')
    assert.ok(
      icon.getBoundingClientRect().left < command.input.getBoundingClientRect().left,
      'the icon comes first',
    )

    const list = getComputedStyle(command.list)
    assert.strictEqual(list.maxHeight, '288px', 'max-h-72')
    assert.strictEqual(list.overflowY, 'auto')

    const [suggestions] = command.groups
    assert.strictEqual(getComputedStyle(suggestions!).paddingTop, '4px', 'p-1')
    const heading = getComputedStyle(suggestions!.querySelector('[cmdk-group-heading]')!)
    assert.strictEqual(heading.fontSize, '12px', 'text-xs')
    assert.strictEqual(heading.fontWeight, '500', 'font-medium')
    assert.strictEqual(heading.paddingLeft, '8px', 'px-2')
    assert.strictEqual(heading.paddingTop, '6px', 'py-1.5')

    const separator = command.separators[0]!
    assert.strictEqual(getComputedStyle(separator).height, '1px', 'h-px')
    assert.strictEqual(getComputedStyle(separator).marginLeft, '-4px', '-mx-1')
    assert.false(transparent(getComputedStyle(separator).backgroundColor), 'bg-border')

    const calendar = command.item('Calendar')
    const item = getComputedStyle(calendar)
    assert.strictEqual(item.display, 'flex')
    assert.strictEqual(item.alignItems, 'center')
    assert.strictEqual(item.columnGap, '8px', 'gap-2')
    assert.strictEqual(item.paddingLeft, '8px', 'px-2')
    assert.strictEqual(item.paddingTop, '6px', 'py-1.5')
    assert.strictEqual(item.fontSize, '14px', 'text-sm')
    assert.strictEqual(item.borderTopLeftRadius, '6px', 'rounded-sm')
    assert.false(transparent(item.backgroundColor), 'the selected item is bg-muted')
    assert.strictEqual(getComputedStyle(calendar.querySelector('svg')!).width, '16px', 'size-4')
    const indicator = getComputedStyle(calendar.querySelector('.jn-command-item-indicator')!)
    assert.strictEqual(indicator.opacity, '0', 'the check shows only when checked')

    const disabled = getComputedStyle(command.item('Search Emoji'))
    assert.strictEqual(disabled.opacity, '0.5')
    assert.strictEqual(disabled.pointerEvents, 'none')
    assert.true(transparent(disabled.backgroundColor))

    const withShortcut = command.item('Settings ⌘S')
    assert.strictEqual(
      getComputedStyle(withShortcut.querySelector('.jn-command-item-indicator')!).display,
      'none',
      'an item with a shortcut has no check',
    )
    const shortcut = getComputedStyle(withShortcut.querySelector('.jn-command-shortcut')!)
    assert.strictEqual(shortcut.fontSize, '12px', 'text-xs')
    assert.strictEqual(shortcut.letterSpacing, '1.2px', 'tracking-widest')
    assert.true(parseFloat(shortcut.marginLeft) > 0, 'ms-auto pushes it to the end')

    await command.search('zzz')
    const empty = getComputedStyle(command.empty!)
    assert.strictEqual(empty.paddingTop, '24px', 'py-6')
    assert.strictEqual(empty.textAlign, 'center')
    assert.strictEqual(empty.fontSize, '14px')
    await a11yAudit()
  })

  test('it filters, ranks and chooses as the primitive does', async function (assert) {
    const chosen: string[] = []
    const choose = (value: string) => chosen.push(value)
    await render(
      <template>
        <Command @onSelect={{choose}} as |c|>
          <c.Input placeholder="Type a command or search..." />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Suggestions">
              <c.Item>Calendar</c.Item>
              <c.Item>Search Emoji</c.Item>
              <c.Item>Calculator</c.Item>
            </c.Group>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(command.selected, 'Calendar')
    await command.search('calc')
    assert.deepEqual(command.itemValues, ['Calculator'])
    await command.press('Enter')
    assert.deepEqual(chosen, ['Calculator'])
    await command.clear()
    await command.press('End')
    assert.strictEqual(command.selected, 'Calculator')
    assert.strictEqual(command.status, '3 results')
    await a11yAudit()
  })

  test('the search icon and the check take icons of your own, and the addon focuses the input', async function (assert) {
    await render(
      <template>
        <Command as |c|>
          <c.Input @searchIcon={{Zap}} aria-label="Search" />
          <c.List>
            <c.Item @checkIcon={{Circle}} data-checked="true">Apple</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    const addon = command.input.parentElement!.querySelector<HTMLElement>('.jn-input-group-addon')!
    const search = new IconHarness({ within: addon })
    assert.dom(search.element).hasClass('jn-command-input-icon')
    assert.strictEqual(
      addon.querySelector('svg')!.innerHTML.includes('path'),
      true,
      "lucide's zap is drawn",
    )
    const indicator = command.item('Apple').querySelector('.jn-command-item-indicator')!
    assert.dom(indicator.querySelector('circle')).exists("lucide's circle is drawn")
    assert.strictEqual(
      getComputedStyle(indicator).opacity,
      '1',
      'group-data-[checked=true]: the check shows',
    )

    await click(addon)
    assert.true(command.hasFocus)
    await a11yAudit()
  })

  test('CommandDialog: a command a third of the way down the page, with no close button', async function (assert) {
    const state = new Open()
    await render(
      <template>
        <button type="button" {{on "click" (fn state.setOpen true)}}>Open Menu</button>
        <CommandDialog @open={{state.open}} @onOpenChange={{state.setOpen}} @name="palette">
          <Command as |c|>
            <c.Input placeholder="Type a command or search..." />
            <c.List>
              <c.Empty>No results found.</c.Empty>
              <c.Group @heading="Suggestions">
                <c.Item>Calendar</c.Item>
                <c.Item>Search Emoji</c.Item>
              </c.Group>
            </c.List>
          </Command>
        </CommandDialog>
      </template>,
    )
    const palette = new CommandDialogHarness('palette')
    await click('button')
    assert.true(palette.isOpen)
    const content = palette.content!
    settle(content)
    assert
      .dom(content)
      .hasClass('jn-dialog-content')
      .hasClass('jn-command-dialog')
      .hasAttribute('data-slot', 'dialog-content')
    assert.strictEqual(palette.closeButton, null, 'upstream shows none')
    assert.strictEqual(palette.label, 'Command Palette')
    assert.strictEqual(palette.descriptionText, 'Search for a command to run...')
    const header = content.querySelector<HTMLElement>('[data-slot="dialog-header"]')!
    assert.strictEqual(getComputedStyle(header).position, 'absolute', 'the header is sr-only')
    assert.strictEqual(header.getBoundingClientRect().width, 1)

    const style = getComputedStyle(content)
    const rect = content.getBoundingClientRect()
    assert.ok(Math.abs(rect.top - window.innerHeight / 3) <= 1, 'top-1/3, translate-y-0')
    assert.ok(
      Math.abs(rect.left + rect.width / 2 - window.innerWidth / 2) <= 1,
      'centred across the page',
    )
    assert.strictEqual(style.paddingTop, '0px', 'p-0')
    assert.strictEqual(style.overflow, 'hidden')
    assert.strictEqual(style.borderTopLeftRadius, '14px', 'rounded-xl!')
    assert.strictEqual(
      getComputedStyle(palette.command.item('Calendar')).borderTopLeftRadius,
      '10px',
      'in a dialog, items are rounded-lg',
    )
    assert.true(palette.command.hasFocus, 'focus is in the search box')
    await a11yAudit()

    await palette.command.search('emoji')
    await palette.pressEscape()
    assert.false(state.open)
    assert.dom('button').isFocused()
  })

  test('CommandDialog: @hotkey, @title, @description and @showCloseButton', async function (assert) {
    await render(
      <template>
        <CommandDialog
          @hotkey="mod+j"
          @title="Palette"
          @description="Run something"
          @showCloseButton={{true}}
          @closeLabel="Dismiss"
          as |d|
        >
          <Command @onSelect={{fn d.setOpen false}} as |c|>
            <c.Input aria-label="Search" />
            <c.List><c.Item>Calendar</c.Item></c.List>
          </Command>
        </CommandDialog>
      </template>,
    )
    const palette = new CommandDialogHarness()
    await palette.pressHotkey('mod+j')
    assert.true(palette.isOpen)
    assert.strictEqual(palette.label, 'Palette')
    assert.strictEqual(palette.descriptionText, 'Run something')
    assert.dom(palette.closeButton).hasText('Dismiss')
    await a11yAudit()

    await palette.command.press('Enter')
    assert.false(palette.isOpen, 'choosing closes it')
    await palette.pressHotkey('mod+j')
    await palette.close()
    assert.false(palette.isOpen, 'the close button closes it')
  })

  test('RTL: the icon starts the input, and shortcuts end the items, on the left', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Command class="w-96" as |c|>
            <c.Input placeholder="اكتب أمرًا أو ابحث..." />
            <c.List @label="اقتراحات">
              <c.Item>
                <Icon @icon={{User}} />
                <span>الملف الشخصي</span>
                <c.Shortcut>⌘P</c.Shortcut>
              </c.Item>
            </c.List>
          </Command>
        </DirectionProvider>
      </template>,
    )
    const command = new CommandHarness()
    const addon = command.input.parentElement!.querySelector<HTMLElement>('.jn-input-group-addon')!
    assert.strictEqual(getComputedStyle(addon).paddingRight, '8px', 'ps-2 is on the right')
    assert.ok(
      addon.getBoundingClientRect().left > command.input.getBoundingClientRect().left,
      'the icon is at the right, where the line starts',
    )
    const item = command.items[0]!
    const shortcut = item.querySelector('.jn-command-shortcut')!
    assert.ok(
      shortcut.getBoundingClientRect().left <
        item.querySelector('span')!.getBoundingClientRect().left,
      'the shortcut is at the left, where the line ends',
    )
    await a11yAudit()
  })
})
