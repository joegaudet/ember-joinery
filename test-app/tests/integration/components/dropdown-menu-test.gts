import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { fn } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LogOut, User } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'
import { ButtonHarness, DropdownMenuHarness, pressKey } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

const rect = (element: Element) => element.getBoundingClientRect()

/** The colour a token resolves to, as computed styles report colours. */
function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.setProperty('color', `var(${name})`)
  document.body.append(probe)
  const color = getComputedStyle(probe).color
  probe.remove()
  return color
}

/** Ends the content's entry animation, so its computed style is the resting one. */
function finishAnimations(element: Element) {
  for (const animation of element.getAnimations({ subtree: true })) animation.finish()
}

class State {
  @tracked statusBar = true
  @tracked position = 'bottom'
  setStatusBar = (checked: boolean) => (this.statusBar = checked)
  setPosition = (value: string) => (this.position = value)
}

module('Integration | components | dropdown-menu', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream’s classes and slots, with a Button of your own as the trigger', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DropdownMenu @name="account" as |m|>
          <Button @variant="outline" {{m.trigger}}>Open</Button>
          <m.Content>
            <m.Group>
              <m.Label>My Account</m.Label>
              <m.Item>Profile <m.Shortcut>⇧⌘P</m.Shortcut></m.Item>
            </m.Group>
            <m.Separator />
            <m.CheckboxItem @checked={{state.statusBar}} @onCheckedChange={{state.setStatusBar}}>
              Status Bar
            </m.CheckboxItem>
            <m.RadioGroup @value={{state.position}} @onValueChange={{state.setPosition}} as |g|>
              <g.Item @value="top">Top</g.Item>
              <g.Item @value="bottom">Bottom</g.Item>
            </m.RadioGroup>
            <m.Sub as |s|>
              <s.Trigger>Invite users</s.Trigger>
              <m.Portal>
                <s.Content><m.Item>Email</m.Item></s.Content>
              </m.Portal>
            </m.Sub>
            <m.Item @variant="destructive">Log out</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness('account')
    const button = new ButtonHarness()
    assert.strictEqual(menu.trigger, button.element, 'the Button is the trigger')
    assert
      .dom(menu.trigger)
      .hasAttribute('data-slot', 'button', 'it keeps its own slot, as upstream’s asChild does')
      .hasAttribute('aria-haspopup', 'menu')

    await menu.open()
    const content = menu.content!
    assert
      .dom(content)
      .hasClass('jn-dropdown-menu-content')
      .hasClass('jn-menu-target')
      .doesNotHaveClass('jn-menu-translucent', 'shadcn’s default menu colour drops it')
      .hasAttribute('data-slot', 'dropdown-menu-content')
      .hasAttribute('data-side', 'bottom')
      .hasAttribute('data-align', 'start')
    assert.dom('[data-slot="dropdown-menu-group"]', content).exists()
    assert.dom('[data-slot="dropdown-menu-label"]', content).hasClass('jn-dropdown-menu-label')
    assert
      .dom(menu.item('Profile'))
      .hasClass('jn-dropdown-menu-item')
      .hasClass('group/dropdown-menu-item')
      .hasAttribute('data-slot', 'dropdown-menu-item')
      .hasAttribute('data-variant', 'default')
      .doesNotHaveAttribute('data-inset')
    assert
      .dom('[data-slot="dropdown-menu-shortcut"]', menu.item('Profile'))
      .hasClass('jn-dropdown-menu-shortcut')
      .hasText('⇧⌘P')
    assert.strictEqual(menu.shortcut('Profile'), '⇧⌘P')
    assert
      .dom('[data-slot="dropdown-menu-separator"]', content)
      .hasClass('jn-dropdown-menu-separator')
    assert
      .dom(menu.item('Status Bar'))
      .hasClass('jn-dropdown-menu-checkbox-item')
      .hasAttribute('data-slot', 'dropdown-menu-checkbox-item')
    assert
      .dom('[data-slot="dropdown-menu-checkbox-item-indicator"]', menu.item('Status Bar'))
      .hasClass('jn-dropdown-menu-item-indicator')
    assert.dom('svg.lucide', menu.item('Status Bar')).exists('a check mark while checked')
    assert.dom('[data-slot="dropdown-menu-radio-group"]', content).hasAttribute('role', 'group')
    assert.dom(menu.item('Bottom')).hasClass('jn-dropdown-menu-radio-item')
    assert
      .dom('[data-slot="dropdown-menu-radio-item-indicator"] svg', menu.item('Bottom'))
      .exists('the checked radio item has the mark')
    assert
      .dom('[data-slot="dropdown-menu-radio-item-indicator"] svg', menu.item('Top'))
      .doesNotExist()
    assert
      .dom(menu.item('Invite users'))
      .hasClass('jn-dropdown-menu-sub-trigger')
      .hasAttribute('data-slot', 'dropdown-menu-sub-trigger')
    assert.dom('svg.jn-rtl-flip', menu.item('Invite users')).exists('its chevron')
    assert.strictEqual(menu.variant('Log out'), 'destructive')
    await a11yAudit()

    const sub = menu.sub('Invite users')
    await sub.open()
    assert
      .dom(sub.content)
      .hasClass('jn-dropdown-menu-sub-content')
      .hasClass('jn-menu-target')
      .hasAttribute('data-slot', 'dropdown-menu-sub-content')
    await a11yAudit()
  })

  test('its style sheet sizes, colours and places it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 200px">
          <DropdownMenu @defaultOpen={{true}} as |m|>
            <m.Trigger style="width: 100px">Open</m.Trigger>
            <m.Content>
              <m.Label>My Account</m.Label>
              <m.Item><Icon @icon={{User}} />Profile<m.Shortcut>⌘P</m.Shortcut></m.Item>
              <m.Item @inset={{true}}>Inset</m.Item>
              <m.Item @disabled={{true}}>API</m.Item>
              <m.Separator />
              <m.CheckboxItem @checked={{true}}>Status Bar</m.CheckboxItem>
              <m.Sub as |s|>
                <s.Trigger>More</s.Trigger>
                <s.Content><m.Item>Email</m.Item></s.Content>
              </m.Sub>
              <m.Item @variant="destructive"><Icon @icon={{LogOut}} />Log out</m.Item>
            </m.Content>
          </DropdownMenu>
        </div>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    const content = menu.content!
    finishAnimations(content)
    const style = getComputedStyle(content)
    assert.strictEqual(style.minWidth, '128px', 'min-w-32')
    assert.strictEqual(style.paddingTop, '4px', 'p-1')
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style.backgroundColor, token('--popover'), 'bg-popover')
    assert.strictEqual(style.color, token('--popover-foreground'), 'text-popover-foreground')
    assert.notStrictEqual(style.boxShadow, 'none', 'shadow-md and its ring')
    assert.strictEqual(style.overflowY, 'auto', 'it scrolls when it must')
    assert.ok(px(style.maxHeight) > 0, 'no taller than the room below the trigger')
    assert.ok(style.transformOrigin, 'from Radix’s custom property')
    assert.strictEqual(rect(content).width, 128, 'min-w-32, when its trigger is narrower')

    const t = rect(menu.trigger)
    const c = rect(content)
    assert.true(Math.abs(c.top - (t.bottom + 4)) <= 1, `4px below its trigger (${c.top})`)
    assert.true(Math.abs(c.left - t.left) <= 1, 'lined up with its start')

    const label = getComputedStyle(content.querySelector('[data-slot="dropdown-menu-label"]')!)
    assert.strictEqual(px(label.fontSize), 12, 'the label is text-xs')
    assert.strictEqual(label.fontWeight, '500', 'font-medium')
    assert.strictEqual(label.color, token('--muted-foreground'))

    const item = getComputedStyle(menu.item('Profile'))
    assert.strictEqual(item.display, 'flex')
    assert.strictEqual(item.alignItems, 'center')
    assert.strictEqual(px(item.fontSize), 14, 'text-sm')
    assert.strictEqual(item.paddingInlineStart, '6px', 'px-1.5')
    assert.strictEqual(item.paddingTop, '4px', 'py-1')
    assert.strictEqual(item.columnGap, '6px', 'gap-1.5')
    assert.strictEqual(item.borderTopLeftRadius, '8px', 'rounded-md')
    assert.strictEqual(item.userSelect, 'none', 'select-none')
    assert.strictEqual(
      getComputedStyle(menu.item('Profile').querySelector('svg')!).width,
      '16px',
      'its icon is size-4',
    )
    assert.strictEqual(
      getComputedStyle(menu.item('Inset')).paddingInlineStart,
      '28px',
      '@inset is ps-7',
    )
    assert.strictEqual(
      getComputedStyle(menu.item('API')).opacity,
      '0.5',
      'a disabled item is faded',
    )
    assert.strictEqual(getComputedStyle(menu.item('API')).pointerEvents, 'none')

    const shortcut = menu.item('Profile').querySelector('[data-slot="dropdown-menu-shortcut"]')!
    assert.strictEqual(px(getComputedStyle(shortcut).fontSize), 12, 'the shortcut is text-xs')
    assert.true(
      Math.abs(rect(shortcut).right - (rect(menu.item('Profile')).right - 6)) <= 1,
      'at the item’s end (ms-auto)',
    )

    const separator = getComputedStyle(
      content.querySelector('[data-slot="dropdown-menu-separator"]')!,
    )
    assert.strictEqual(separator.height, '1px')
    assert.strictEqual(separator.backgroundColor, token('--border'))

    const checkbox = menu.item('Status Bar')
    assert.strictEqual(
      getComputedStyle(checkbox).paddingInlineEnd,
      '32px',
      'room for the check: pe-8',
    )
    const indicator = checkbox.querySelector<HTMLElement>('[data-slot$="indicator"]')!
    assert.strictEqual(getComputedStyle(indicator).position, 'absolute')
    assert.true(
      Math.abs(rect(indicator).right - (rect(checkbox).right - 8)) <= 1,
      'the check at the end: end-2',
    )

    const destructive = getComputedStyle(menu.item('Log out'))
    assert.strictEqual(destructive.color, token('--destructive'), 'a destructive item is red')

    const chevron = menu.item('More').querySelector('svg.jn-rtl-flip')!
    assert.true(
      Math.abs(rect(chevron).right - (rect(menu.item('More')).right - 6)) <= 1,
      'the chevron at the end (ms-auto)',
    )
    await menu.sub('More').open()
    const subContent = menu.sub('More').content!
    finishAnimations(subContent)
    assert.strictEqual(getComputedStyle(subContent).minWidth, '96px', 'min-w-[96px]')
    assert.notStrictEqual(getComputedStyle(subContent).boxShadow, 'none', 'shadow-lg')
    await a11yAudit()
  })

  test('the keyboard and the pointer, with upstream’s look for the focused item', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Open</m.Trigger>
          <m.Content>
            <m.Item>Profile <m.Shortcut>⌘P</m.Shortcut></m.Item>
            <m.Item>Billing</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    assert.strictEqual(menu.highlighted, 'Profile')
    const profile = menu.item('Profile')
    assert.strictEqual(
      getComputedStyle(profile).backgroundColor,
      token('--accent'),
      'focus:bg-accent',
    )
    assert.strictEqual(
      getComputedStyle(profile.querySelector('[data-slot$="shortcut"]')!).color,
      token('--accent-foreground'),
      'the focused item’s shortcut turns too',
    )
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Billing')
    await menu.hover('Profile')
    assert.strictEqual(menu.highlighted, 'Profile')
    await menu.select('Profile')
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('right to left: the content lines up with the trigger’s right, and the chevron turns', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 400px">
          <DirectionProvider @dir="rtl">
            <DropdownMenu @defaultOpen={{true}} as |m|>
              <m.Trigger style="width: 400px">فتح</m.Trigger>
              <m.Content>
                <m.Item @inset={{true}}>الملف الشخصي</m.Item>
                <m.Sub as |s|>
                  <s.Trigger>المزيد</s.Trigger>
                  <s.Content><m.Item>البريد</m.Item></s.Content>
                </m.Sub>
              </m.Content>
            </DropdownMenu>
          </DirectionProvider>
        </div>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    const content = menu.content!
    finishAnimations(content)
    assert.true(
      Math.abs(rect(content).right - rect(menu.trigger).right) <= 1,
      '@align="start" is the right edge',
    )
    // The test container is drawn at half size; the trigger's box is what the content matches.
    assert.strictEqual(rect(content).width, rect(menu.trigger).width, 'as wide as its trigger')
    const inset = getComputedStyle(menu.item('الملف الشخصي'))
    assert.strictEqual(inset.paddingRight, '28px', 'ps-7 is on the right')
    const chevron = menu.item('المزيد').querySelector('svg.jn-rtl-flip')!
    assert.strictEqual(getComputedStyle(chevron).rotate, '180deg', 'the chevron points left')
    assert.true(
      Math.abs(rect(chevron).left - (rect(menu.item('المزيد')).left + 6)) <= 1,
      'at the item’s end, on the left',
    )
    await menu.sub('المزيد').openWithKeyboard()
    assert.strictEqual(menu.sub('المزيد').side, 'left')
    await a11yAudit()
  })

  test('the item modifier styles your own element as an item', async function (assert) {
    const selected: string[] = []
    const select = (name: string) => selected.push(name)
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Open</m.Trigger>
          <m.Content>
            <a href="#profile" {{m.item onSelect=(fn select "profile")}}>Profile</a>
            <a href="#delete" {{m.item variant="destructive" inset=true}}>Delete</a>
            <m.LinkItem @href="#billing">Billing</m.LinkItem>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert
      .dom(menu.item('Profile'))
      .hasClass('jn-dropdown-menu-item')
      .hasAttribute('data-slot', 'dropdown-menu-item')
      .hasAttribute('data-variant', 'default')
    assert
      .dom(menu.item('Delete'))
      .hasAttribute('data-variant', 'destructive')
      .hasAttribute('data-inset')
    assert.strictEqual(getComputedStyle(menu.item('Profile')).display, 'flex', 'styled as an item')
    assert.dom(menu.item('Billing')).hasClass('jn-dropdown-menu-item').hasTagName('a')
    await a11yAudit()
    await menu.select('Profile')
    assert.deepEqual(selected, ['profile'])
    await a11yAudit()
  })
})
