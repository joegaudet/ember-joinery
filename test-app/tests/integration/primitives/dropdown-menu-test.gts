import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, settled, triggerEvent } from '@ember/test-helpers'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { DropdownMenu, Menu } from '@ember-joinery/primitives/dropdown-menu'
import { isScrollLocked } from '@ember-joinery/primitives/scroll-lock'
import {
  DropdownMenuHarness,
  hover,
  pressKey,
  pressOutside,
  setupAnchorFallback,
  typeKeys,
  unhover,
  type TestHooks,
} from '@ember-joinery/test-support'

/** Fixed sizes and none of the browser's popover styles, so edges line up. */
const Styles = <template>
  <style>
    .dm-stage {
      position: fixed;
      top: 100px;
      left: 200px;
    }
    .dm-trigger {
      width: 80px;
      height: 24px;
      padding: 0;
      border: 0;
    }
    .dm-content {
      width: 160px;
      margin: 0;
      padding: 0;
      border: 0;
      overflow: visible;
    }
    .dm-content [role^="menuitem"] {
      height: 24px;
    }
  </style>
</template>

type Assert = Parameters<Parameters<typeof test>[1]>[0]

const rect = (element: Element) => element.getBoundingClientRect()

function near(assert: Assert, actual: number, expected: number, message: string) {
  assert.true(Math.abs(actual - expected) <= 1, `${message} (${actual} ≈ ${expected})`)
}

class State {
  @tracked open = false
  @tracked checked: boolean | 'indeterminate' = false
  @tracked value = 'bottom'
  changes: unknown[] = []
  selected: string[] = []
  setOpen = (open: boolean) => {
    this.changes.push(open)
    this.open = open
  }
  setChecked = (checked: boolean) => {
    this.changes.push(checked)
    this.checked = checked
  }
  setValue = (value: string) => {
    this.changes.push(value)
    this.value = value
  }
  select = (name: string) => this.selected.push(name)
  keepOpen = (event: Event) => event.preventDefault()
}

/** Placement, in both ways of anchoring: each module runs these. */
function placementTests(hooks: TestHooks) {
  void hooks

  test('its content goes below the trigger, centred and touching it, as Radix’s', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="dm-stage">
          <DropdownMenu @defaultOpen={{true}} as |m|>
            <m.Trigger class="dm-trigger">Open</m.Trigger>
            <m.Content class="dm-content"><m.Item>Profile</m.Item></m.Content>
          </DropdownMenu>
        </div>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    const t = rect(menu.trigger)
    const c = rect(menu.content!)
    near(assert, c.top, t.bottom, 'touching the trigger')
    near(assert, c.left + c.width / 2, t.left + t.width / 2, 'centred')
    assert.strictEqual(menu.side, 'bottom')
    assert.strictEqual(menu.align, 'center')
    await a11yAudit()
  })

  test('a submenu goes beside its trigger, aligned with its top; on the left, right to left', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="dm-stage">
          <DropdownMenu @defaultOpen={{true}} as |m|>
            <m.Trigger class="dm-trigger">Open</m.Trigger>
            <m.Content class="dm-content" @align="start">
              <m.Sub as |s|>
                <s.Trigger>Invite users</s.Trigger>
                <s.Content class="dm-content"><m.Item>Email</m.Item></s.Content>
              </m.Sub>
            </m.Content>
          </DropdownMenu>
        </div>
        <div class="dm-stage" style="left: 600px" dir="rtl">
          <DropdownMenu @name="rtl" @defaultOpen={{true}} as |m|>
            <m.Trigger class="dm-trigger">فتح</m.Trigger>
            <m.Content class="dm-content" @align="start">
              <m.Sub as |s|>
                <s.Trigger>دعوة</s.Trigger>
                <s.Content class="dm-content"><m.Item>بريد</m.Item></s.Content>
              </m.Sub>
            </m.Content>
          </DropdownMenu>
        </div>
      </template>,
    )
    const ltr = new DropdownMenuHarness().sub('Invite users')
    await ltr.open()
    const trigger = rect(ltr.trigger)
    const content = rect(ltr.content!)
    near(assert, content.left, rect(ltr.trigger.closest('[role=menu]')!).right, 'on the right')
    near(assert, content.top, trigger.top, 'level with the trigger')
    assert.strictEqual(ltr.side, 'right')

    const rtl = new DropdownMenuHarness('rtl').sub('دعوة')
    await rtl.open()
    const rtlContent = rect(rtl.content!)
    near(assert, rtlContent.right, rect(rtl.trigger.closest('[role=menu]')!).left, 'on the left')
    assert.strictEqual(rtl.side, 'left')
    await a11yAudit()
  })
}

module('Integration | primitives | dropdown-menu', function (hooks) {
  setupRenderingTest(hooks)

  placementTests(hooks)

  test('closed, it renders a menu button and no content', async function (assert) {
    await render(
      <template>
        <DropdownMenu @name="account" as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content><m.Item>Profile</m.Item></m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness('account')
    assert
      .dom(menu.trigger)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('aria-haspopup', 'menu')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('data-state', 'closed')
      .doesNotHaveAttribute('aria-controls')
      .hasAttribute('id')
    assert.false(menu.isOpen)
    assert.strictEqual(menu.content, null, 'no content while closed')
    assert.strictEqual(getComputedStyle(menu.element).display, 'contents')
    await a11yAudit()
  })

  test('a press opens it: a menu named by its trigger, in the top layer, with focus on the menu', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content>
            <m.Group>
              <m.Label>My Account</m.Label>
              <m.Item>Profile</m.Item>
              <m.Item>Billing</m.Item>
            </m.Group>
            <m.Separator />
            <m.Item>Log out</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.true(menu.isOpen)
    assert.true(menu.isShown, 'in the top layer')
    const content = menu.content!
    assert
      .dom(content)
      .hasAttribute('role', 'menu')
      .hasAttribute('aria-orientation', 'vertical')
      .hasAttribute('data-state', 'open')
      .hasAttribute('aria-labelledby', menu.trigger.id)
      .hasAttribute('data-test-jn-owner', menu.element.id)
    assert
      .dom(menu.trigger)
      .hasAttribute('aria-controls', content.id)
      .hasAttribute('data-state', 'open')
    assert.strictEqual(menu.label, 'Account', 'its trigger names it')
    assert.deepEqual(menu.items, ['Profile', 'Billing', 'Log out'])
    assert.deepEqual(menu.labels, ['My Account'])
    assert.strictEqual(menu.separators, 1)
    assert.dom('[role=group]', content).exists()
    assert.dom('[role=separator]', content).hasAttribute('aria-orientation', 'horizontal')
    for (const item of menu.itemElements) {
      assert.dom(item).hasAttribute('role', 'menuitem').hasAttribute('tabindex', '-1')
    }
    assert.dom(content).isFocused('a press leaves focus on the menu, not an item')
    assert.strictEqual(menu.highlighted, null)
    assert.notOk(menu.trigger.matches(':focus'), 'the press kept focus off the trigger')
    await a11yAudit()
  })

  test('the keyboard opens it on the first item: Enter, Space and ArrowDown', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content>
            <m.Item @disabled={{true}}>Profile</m.Item>
            <m.Item>Billing</m.Item>
            <m.Item>Log out</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    for (const key of ['Enter', ' ', 'ArrowDown'] as const) {
      await menu.openWithKeyboard(key)
      assert.true(menu.isOpen, `${JSON.stringify(key)} opens it`)
      assert.strictEqual(menu.highlighted, 'Billing', 'on the first item it can focus')
      assert.dom(menu.item('Billing')).hasAttribute('data-highlighted')
      await menu.pressEscape()
      assert.false(menu.isOpen)
      assert.dom(menu.trigger).isFocused('Escape puts focus back on the trigger')
    }
    await focus(menu.trigger)
    assert.true(await pressKey('Enter'), 'the trigger takes the key')
    assert.true(await pressKey('Enter'), 'Enter on the first item selects it')
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('the arrow keys, Home and End move between the items, skipping disabled ones', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content>
            <m.Item>Profile</m.Item>
            <m.Item @disabled={{true}}>Billing</m.Item>
            <m.Separator />
            <m.Item>Settings</m.Item>
            <m.Item>Log out</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    assert.strictEqual(menu.highlighted, 'Profile')
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Settings', 'past the disabled item')
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Log out')
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Log out', 'no further without @loop')
    await pressKey('Home')
    assert.strictEqual(menu.highlighted, 'Profile')
    await pressKey('ArrowUp')
    assert.strictEqual(menu.highlighted, 'Profile', 'no further without @loop')
    await pressKey('End')
    assert.strictEqual(menu.highlighted, 'Log out')
    await pressKey('PageUp')
    assert.strictEqual(menu.highlighted, 'Profile')
    await pressKey('PageDown')
    assert.strictEqual(menu.highlighted, 'Log out')
    assert.true(await pressKey('Tab'), 'Tab stays in the menu')
    assert.strictEqual(menu.highlighted, 'Log out')
    assert.true(menu.isDisabled('Billing'))
    assert
      .dom(menu.item('Billing'))
      .hasAttribute('data-disabled')
      .hasAttribute('aria-disabled', 'true')
    await a11yAudit()
  })

  test('@loop goes round; opened by a press, the arrows start from the ends', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content @loop={{true}}>
            <m.Item>Profile</m.Item>
            <m.Item>Billing</m.Item>
            <m.Item>Log out</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.strictEqual(menu.highlighted, null)
    await pressKey('ArrowUp')
    assert.strictEqual(menu.highlighted, 'Log out', 'ArrowUp from the menu goes to the last')
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Profile', 'round to the first')
    await pressKey('ArrowUp')
    assert.strictEqual(menu.highlighted, 'Log out', 'and back round')
    await menu.close()
    await menu.open()
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Profile', 'ArrowDown from the menu goes to the first')
    await a11yAudit()
  })

  test('typing moves to the item whose text starts with what is typed', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content>
            <m.Item>Profile</m.Item>
            <m.Item @onSelect={{fn state.select "billing"}}>Billing</m.Item>
            <m.Item @disabled={{true}}>Blocked</m.Item>
            <m.Item>Bookmarks</m.Item>
            <m.Item @textValue="settings">⚙ Settings</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    await typeKeys('b')
    assert.strictEqual(menu.highlighted, 'Billing')
    await typeKeys('b')
    assert.strictEqual(
      menu.highlighted,
      'Bookmarks',
      'the same letter again moves on, past a disabled item',
    )
    await typeKeys('b')
    assert.strictEqual(menu.highlighted, 'Billing', 'and round')
    await new Promise(resolve => setTimeout(resolve, 1100))
    await typeKeys('se')
    assert.strictEqual(menu.highlighted, '⚙ Settings', '@textValue is what it matches')
    await new Promise(resolve => setTimeout(resolve, 1100))
    await typeKeys('bi')
    assert.strictEqual(menu.highlighted, 'Billing')
    await pressKey(' ')
    assert.true(menu.isOpen, 'Space while typing is part of the search, not a press')
    assert.deepEqual(state.selected, [])
    await new Promise(resolve => setTimeout(resolve, 1100))
    await pressKey(' ')
    assert.deepEqual(state.selected, ['billing'], 'Space selects once the search is over')
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('selecting an item calls @onSelect, closes the menu and puts focus back on the trigger', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content>
            <m.Item @onSelect={{fn state.select "profile"}}>Profile</m.Item>
            <m.Item @onSelect={{state.keepOpen}}>Stay</m.Item>
            <m.Item @disabled={{true}} @onSelect={{fn state.select "billing"}}>Billing</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    await menu.select('Stay')
    assert.true(menu.isOpen, '@onSelect’s preventDefault() keeps it open')
    await click(menu.item('Billing'))
    assert.true(menu.isOpen, 'a disabled item selects nothing')
    await menu.select('Profile')
    assert.deepEqual(state.selected, ['profile'])
    assert.false(menu.isOpen)
    assert.dom(menu.trigger).isFocused()

    await menu.openWithKeyboard()
    await pressKey(' ')
    assert.deepEqual(state.selected, ['profile', 'profile'], 'Space selects the focused item')
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('a press on the trigger, dragged to an item and let go there, selects it', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content>
            <m.Item @onSelect={{fn state.select "profile"}}>Profile</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await triggerEvent(menu.trigger, 'pointerdown', { button: 0, pointerType: 'mouse' })
    assert.true(menu.isOpen)
    await triggerEvent(menu.item('Profile'), 'pointerup', { button: 0, pointerType: 'mouse' })
    assert.deepEqual(state.selected, ['profile'])
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('the pointer focuses the items it rests on, and leaving one gives focus back to the menu', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content>
            <m.Item>Profile</m.Item>
            <m.Item @disabled={{true}}>Billing</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    await menu.hover('Profile')
    assert.strictEqual(menu.highlighted, 'Profile')
    assert.dom(menu.item('Profile')).hasAttribute('data-highlighted')
    await unhover(menu.item('Profile'), { side: 'top' })
    assert.dom(menu.content).isFocused('back on the menu')
    assert.dom(menu.item('Profile')).doesNotHaveAttribute('data-highlighted')
    await menu.hover('Billing')
    assert.strictEqual(menu.highlighted, null, 'a disabled item takes no focus')
    await hover(menu.item('Profile'), { pointerType: 'touch' })
    assert.strictEqual(menu.highlighted, null, 'a touch doesn’t hover')
    await a11yAudit()
  })

  test('Escape and a press outside close it; @open and @onOpenChange control it', async function (assert) {
    const state = new State()
    await render(
      <template>
        <button type="button" class="outside">Outside</button>
        <DropdownMenu @open={{state.open}} @onOpenChange={{state.setOpen}} as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content><m.Item>Profile</m.Item></m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.true(menu.isOpen)
    assert.deepEqual(state.changes, [true])
    await menu.pressEscape()
    assert.false(menu.isOpen)
    assert.deepEqual(state.changes, [true, false])
    await menu.open()
    await pressOutside()
    assert.false(menu.isOpen, 'a press outside closes it')
    await menu.open()
    // The pointer going down on the page, which a modal menu keeps from reaching anything there.
    await triggerEvent(document.documentElement, 'pointerdown', { button: 0, pointerType: 'mouse' })
    assert.false(menu.isOpen)
    assert.dom(menu.trigger).isFocused('a modal menu still gives focus back to the trigger')
    state.open = true
    await settled()
    assert.true(menu.isShown, 'opened by @open')
    await a11yAudit()
  })

  test('modal (the default), it keeps the pointer, focus and scrolling off the page, which is inert', async function (assert) {
    await render(
      <template>
        <p class="page">The page</p>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <m.Content><m.Item>Profile</m.Item></m.Content>
        </DropdownMenu>
        <DropdownMenu @name="plain" @modal={{false}} as |m|>
          <m.Trigger>Plain</m.Trigger>
          <m.Content><m.Item>Profile</m.Item></m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.strictEqual(document.body.style.pointerEvents, 'none', 'the page ignores the pointer')
    assert.true(isScrollLocked(), 'and doesn’t scroll')
    assert.dom('.page').hasAttribute('inert', '', 'and is inert')
    await menu.pressEscape()
    assert.strictEqual(document.body.style.pointerEvents, '')
    assert.false(isScrollLocked())
    assert.dom('.page').doesNotHaveAttribute('inert')

    const plain = new DropdownMenuHarness('plain')
    await plain.open()
    assert.strictEqual(document.body.style.pointerEvents, '', 'a non-modal one leaves the page be')
    assert.false(isScrollLocked())
    assert.dom('.page').doesNotHaveAttribute('inert')
    await focus(menu.trigger)
    assert.false(plain.isOpen, 'focus going outside a non-modal menu closes it')
    assert.dom(menu.trigger).isFocused('and leaves focus where it went')
    await a11yAudit()
  })

  test('checkbox items: their state, which is yours, and the indicator', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>View</m.Trigger>
          <m.Content>
            <m.CheckboxItem
              @checked={{state.checked}}
              @onCheckedChange={{state.setChecked}}
              as |item|
            >
              <item.Indicator class="check">✓</item.Indicator>
              Panel
            </m.CheckboxItem>
            <m.CheckboxItem @checked={{true}} as |item|>
              <item.Indicator class="check">✓</item.Indicator>
              Fixed
            </m.CheckboxItem>
            <m.CheckboxItem>Off</m.CheckboxItem>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.strictEqual(menu.role('Panel'), 'menuitemcheckbox')
    assert.false(menu.isChecked('Panel'))
    assert.dom(menu.item('Panel')).hasAttribute('data-state', 'unchecked')
    assert.dom('.check', menu.item('Panel')).doesNotExist('no indicator while unchecked')
    assert.true(menu.isChecked('Fixed'))
    assert.dom(menu.item('Fixed')).hasAttribute('data-state', 'checked')
    assert.dom('.check', menu.item('Fixed')).exists().hasAttribute('data-state', 'checked')
    assert.strictEqual(menu.checked('Off'), 'false', 'unchecked without @checked')
    await a11yAudit()

    await menu.select('Panel')
    assert.false(menu.isOpen, 'selecting closes the menu')
    assert.deepEqual(state.changes, [true])
    await menu.open()
    assert.true(menu.isChecked('Panel'))
    await menu.select('Fixed')
    await menu.open()
    assert.true(menu.isChecked('Fixed'), '@checked without a handler stays')

    state.checked = 'indeterminate'
    await settled()
    assert.strictEqual(menu.checked('Panel'), 'mixed')
    assert.dom(menu.item('Panel')).hasAttribute('data-state', 'indeterminate')
    assert.dom('.check', menu.item('Panel')).exists('shown while indeterminate')
    await menu.select('Panel')
    assert.deepEqual(state.changes, [true, true], 'indeterminate asks for checked')
    await a11yAudit()
  })

  test('radio items: the one whose value is the group’s is checked', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Position</m.Trigger>
          <m.Content>
            <m.RadioGroup @value={{state.value}} @onValueChange={{state.setValue}} as |g|>
              <g.Item @value="top" as |item|><item.Indicator>●</item.Indicator>Top</g.Item>
              <g.Item @value="bottom" as |item|><item.Indicator>●</item.Indicator>Bottom</g.Item>
            </m.RadioGroup>
            <m.Separator />
            <m.RadioGroup @value="light" as |g|>
              <g.Item @value="light">Light</g.Item>
              <g.Item @value="dark">Dark</g.Item>
            </m.RadioGroup>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.strictEqual(menu.role('Top'), 'menuitemradio')
    assert.false(menu.isChecked('Top'))
    assert.true(menu.isChecked('Bottom'))
    assert
      .dom(menu.item('Bottom'))
      .hasAttribute('data-state', 'checked')
      .hasAttribute('data-test-jn-value', 'bottom')
    assert.dom('[data-test-jn-part=item-indicator]', menu.item('Bottom')).hasText('●')
    assert.dom('[data-test-jn-part=item-indicator]', menu.item('Top')).doesNotExist()
    assert
      .dom('[data-test-jn-part=radio-group]', menu.content)
      .exists({ count: 2 })
      .hasAttribute('role', 'group')
    assert.true(menu.isChecked('Light'))
    await a11yAudit()

    await menu.select('Top')
    assert.deepEqual(state.changes, ['top'])
    await menu.open()
    assert.true(menu.isChecked('Top'))
    assert.false(menu.isChecked('Bottom'))
    await menu.select('Dark')
    await menu.open()
    assert.true(menu.isChecked('Light'), '@value without a handler stays')
    await a11yAudit()
  })

  test('a submenu opens on hover, keeping focus on its trigger', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Team</m.Trigger>
          <m.Content>
            <m.Item>Team</m.Item>
            <m.Sub as |s|>
              <s.Trigger>Invite users</s.Trigger>
              <s.Content>
                <m.Item>Email</m.Item>
                <m.Item>Message</m.Item>
              </s.Content>
            </m.Sub>
            <m.Item>New Team</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    const sub = menu.sub('Invite users')
    assert
      .dom(sub.trigger)
      .hasAttribute('role', 'menuitem')
      .hasAttribute('aria-haspopup', 'menu')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('data-state', 'closed')
    assert.deepEqual(menu.items, ['Team', 'Invite users', 'New Team'], 'its items are its own')
    await sub.open()
    assert.true(sub.isOpen)
    assert.true(sub.isShown, 'in the top layer')
    assert.dom(sub.trigger).hasAttribute('aria-expanded', 'true').hasAttribute('data-state', 'open')
    assert.dom(sub.trigger).isFocused('focus stays on the trigger')
    assert
      .dom(sub.content)
      .hasAttribute('role', 'menu')
      .hasAttribute('aria-labelledby', sub.trigger.id)
      .hasAttribute('id', sub.trigger.getAttribute('aria-controls')!)
    assert.strictEqual(sub.label, 'Invite users')
    assert.deepEqual(sub.items, ['Email', 'Message'])
    await a11yAudit()

    await menu.hover('New Team')
    assert.false(sub.isOpen, 'another item closes it')
    await sub.open()
    await sub.select('Email')
    assert.false(menu.isOpen, 'selecting in a submenu closes the whole menu')
    await a11yAudit()
  })

  test('a submenu’s state is its own: @defaultOpen, and @onOpenChange hears it close with the menu it is in', async function (assert) {
    const changes: Record<string, boolean[]> = { invite: [], more: [] }
    const heard = (name: string) => (open: boolean) => changes[name]!.push(open)
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Team</m.Trigger>
          <m.Content>
            <m.Item>Team</m.Item>
            <m.Sub @onOpenChange={{heard "invite"}} as |s|>
              <s.Trigger>Invite users</s.Trigger>
              <s.Content>
                <m.Item>Email</m.Item>
                <m.Sub @defaultOpen={{true}} @onOpenChange={{heard "more"}} as |more|>
                  <more.Trigger>More</more.Trigger>
                  <more.Content><m.Item>Slack</m.Item></more.Content>
                </m.Sub>
              </s.Content>
            </m.Sub>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    const sub = menu.sub('Invite users')
    assert.false(sub.isOpen)
    await sub.open()
    const more = sub.sub('More')
    assert.true(sub.isOpen)
    assert.true(more.isOpen, '@defaultOpen: it opens with the submenu it is in')
    assert.true(more.isShown)
    assert.deepEqual(changes, { invite: [true], more: [] })
    await a11yAudit()

    await menu.hover('Team')
    assert.false(sub.isOpen, 'another item closes it')
    assert.deepEqual(
      changes,
      { invite: [true, false], more: [false] },
      'a submenu closes with the submenu it is in',
    )

    await sub.open()
    assert.true(more.isOpen, 'rendered anew, it starts from @defaultOpen again')
    await menu.pressEscape()
    assert.false(menu.isOpen)
    assert.deepEqual(changes, { invite: [true, false, true, false], more: [false, false] })
    await a11yAudit()
  })

  test('a submenu’s state is yours with @open and @onOpenChange, which hears it close with its menu and as it goes', async function (assert) {
    class SubState {
      @tracked open = false
      @tracked shown = true
      changes: boolean[] = []
      setOpen = (open: boolean) => {
        this.changes.push(open)
        this.open = open
      }
    }
    const state = new SubState()
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Team</m.Trigger>
          <m.Content>
            <m.Item>Team</m.Item>
            {{#if state.shown}}
              <m.Sub @open={{state.open}} @onOpenChange={{state.setOpen}} as |s|>
                <s.Trigger>Invite users</s.Trigger>
                <s.Content><m.Item>Email</m.Item></s.Content>
              </m.Sub>
            {{/if}}
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.open()
    const sub = menu.sub('Invite users')
    await sub.open()
    assert.true(sub.isOpen)
    assert.deepEqual(state.changes, [true])
    state.open = false
    await settled()
    assert.false(sub.isOpen, 'closed by @open')
    state.open = true
    await settled()
    assert.true(sub.isOpen, 'opened by @open')
    assert.true(sub.isShown)
    await a11yAudit()

    await menu.pressEscape()
    assert.false(menu.isOpen)
    assert.deepEqual(
      state.changes,
      [true, false],
      'its menu closing closes it, through @onOpenChange',
    )
    assert.false(state.open)
    await menu.open()
    assert.false(sub.isOpen, 'so its menu opens with it closed')

    state.open = true
    await settled()
    assert.true(sub.isOpen)
    state.shown = false
    await settled()
    assert.deepEqual(state.changes, [true, false, false], 'it closes as it goes, as Radix’s does')
    assert.false(state.open)
    await a11yAudit()
  })

  test('the keyboard opens a submenu on its first item, and the arrow back closes it', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Team</m.Trigger>
          <m.Content>
            <m.Sub as |s|>
              <s.Trigger>Invite users</s.Trigger>
              <s.Content>
                <m.Item>Email</m.Item>
                <m.Sub as |more|>
                  <more.Trigger>More</more.Trigger>
                  <more.Content><m.Item>Slack</m.Item></more.Content>
                </m.Sub>
              </s.Content>
            </m.Sub>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    assert.strictEqual(menu.highlighted, 'Invite users')
    const sub = menu.sub('Invite users')
    for (const key of ['ArrowRight', 'Enter', ' ']) {
      await pressKey(key)
      assert.true(sub.isOpen, `${JSON.stringify(key)} opens it`)
      assert.strictEqual(sub.highlighted, 'Email', 'on its first item')
      await pressKey('ArrowLeft')
      assert.false(sub.isOpen, 'ArrowLeft closes it')
      assert.dom(sub.trigger).isFocused('and goes back to its trigger')
      assert.true(menu.isOpen)
    }
    await pressKey('ArrowRight')
    await pressKey('ArrowDown')
    const more = sub.sub('More')
    await pressKey('ArrowRight')
    assert.true(more.isOpen, 'a submenu of a submenu')
    assert.strictEqual(more.highlighted, 'Slack')
    await pressKey('ArrowLeft')
    assert.false(more.isOpen)
    assert.true(sub.isOpen, 'only the innermost closes')
    assert.dom(more.trigger).isFocused()
    await pressKey('ArrowRight')
    await pressKey('Escape')
    assert.false(menu.isOpen, 'Escape in a submenu closes the whole menu')
    assert.dom(menu.trigger).isFocused()
    await a11yAudit()
  })

  test('right to left, ArrowLeft opens a submenu and ArrowRight closes it', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <DropdownMenu as |m|>
            <m.Trigger>الفريق</m.Trigger>
            <m.Content>
              <m.Sub as |s|>
                <s.Trigger>دعوة المستخدمين</s.Trigger>
                <s.Content><m.Item>البريد</m.Item></s.Content>
              </m.Sub>
            </m.Content>
          </DropdownMenu>
        </DirectionProvider>
        <DropdownMenu @name="explicit" @dir="rtl" as |m|>
          <m.Trigger>Explicit</m.Trigger>
          <m.Content>
            <m.Sub as |s|>
              <s.Trigger>More</s.Trigger>
              <s.Content><m.Item>Email</m.Item></s.Content>
            </m.Sub>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    const sub = menu.sub('دعوة المستخدمين')
    await pressKey('ArrowRight')
    assert.false(sub.isOpen, 'ArrowRight points away from it')
    await pressKey('ArrowLeft')
    assert.true(sub.isOpen)
    assert.strictEqual(sub.side, 'left')
    await pressKey('ArrowRight')
    assert.false(sub.isOpen)
    await menu.pressEscape()

    const explicit = new DropdownMenuHarness('explicit')
    await explicit.openWithKeyboard()
    assert.dom(explicit.content).hasAttribute('dir', 'rtl', '@dir goes on the content')
    await pressKey('ArrowLeft')
    assert.true(explicit.sub('More').isOpen, '@dir decides the keys')
    await a11yAudit()
  })

  test('the pointer crossing another item on its way to the open submenu leaves it open', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="dm-stage">
          <DropdownMenu @defaultOpen={{true}} as |m|>
            <m.Trigger class="dm-trigger">Open</m.Trigger>
            <m.Content class="dm-content" @align="start">
              <m.Sub as |s|>
                <s.Trigger>Invite users</s.Trigger>
                <s.Content class="dm-content">
                  <m.Item>Email</m.Item>
                  <m.Item>Message</m.Item>
                  <m.Item>Slack</m.Item>
                </s.Content>
              </m.Sub>
              <m.Item>New Team</m.Item>
            </m.Content>
          </DropdownMenu>
        </div>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    const sub = menu.sub('Invite users')
    await sub.open()
    const trigger = rect(sub.trigger)
    const next = menu.item('New Team')
    // The pointer leaves the trigger through its bottom edge, near its right end, heading down
    // and right towards the submenu, and crosses "New Team" on the way.
    const exit = { x: trigger.right - 10, y: trigger.bottom }
    const move = (type: string, target: Element, point: { x: number; y: number }) =>
      target.dispatchEvent(
        new PointerEvent(type, {
          bubbles: type !== 'pointerleave',
          cancelable: type !== 'pointerleave',
          clientX: point.x,
          clientY: point.y,
          pointerType: 'mouse',
        }),
      )
    move('pointermove', sub.trigger, { x: exit.x - 4, y: exit.y - 4 })
    move('pointerleave', sub.trigger, exit)
    move('pointermove', next, { x: exit.x + 6, y: exit.y + 4 })
    await settled()
    assert.true(sub.isOpen, 'still open')
    assert.dom(next).isNotFocused('the item crossed doesn’t take focus')

    // Heading the other way, the pointer is off the grace area: the item takes focus, and the
    // submenu closes.
    move('pointermove', next, { x: rect(next).left + 10, y: rect(next).top + 12 })
    await settled()
    assert.dom(next).isFocused()
    assert.false(sub.isOpen)
    await a11yAudit()
  })

  test('your own elements, with the modifiers: a trigger, an item, a link item', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DropdownMenu as |m|>
          <span role="button" tabindex="0" class="mine" {{m.trigger}}>Mine</span>
          <m.Content>
            <a href="#profile" {{m.item onSelect=(fn state.select "profile")}}>Profile</a>
            <m.LinkItem @href="#billing">Billing</m.LinkItem>
            <m.Item @as="button">Settings</m.Item>
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    assert.dom(menu.trigger).hasClass('mine').hasAttribute('aria-haspopup', 'menu')
    await menu.open()
    assert.dom(menu.item('Profile')).hasTagName('a').hasAttribute('role', 'menuitem')
    assert.dom(menu.item('Billing')).hasTagName('a').hasAttribute('href', '#billing')
    assert.dom(menu.item('Settings')).hasTagName('button')
    await a11yAudit()
    await menu.select('Profile')
    assert.deepEqual(state.selected, ['profile'])
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('ember-primitives’ Menu: Trigger, Content’s Item, LinkItem and Separator, and its positioning', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Styles />
        <div class="dm-stage">
          <Menu @placement="top" @offsetOptions={{8}} as |m|>
            <m.Trigger class="dm-trigger" @stopPropagation={{true}}>Options</m.Trigger>
            <m.Content class="dm-content" as |c|>
              <c.Item @onSelect={{fn state.select "one"}}>Item 1</c.Item>
              <c.Separator />
              <c.LinkItem @href="https://example.com/">Item 3</c.LinkItem>
            </m.Content>
          </Menu>
        </div>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    let clicks = 0
    const count = () => clicks++
    document.addEventListener('click', count)
    await menu.open()
    document.removeEventListener('click', count)
    assert.strictEqual(clicks, 0, '@stopPropagation keeps the click on the trigger')
    assert.deepEqual(menu.items, ['Item 1', 'Item 3'])
    assert.strictEqual(menu.side, 'top', '@placement')
    near(assert, rect(menu.trigger).top - rect(menu.content!).bottom, 8, '@offsetOptions')
    assert
      .dom(menu.item('Item 3'))
      .hasAttribute('target', '_blank')
      .hasAttribute('rel', 'noreferrer noopener')
    await menu.select('Item 1')
    assert.deepEqual(state.selected, ['one'])
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('a disabled trigger opens nothing', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger @disabled={{true}}>Account</m.Trigger>
          <m.Content><m.Item>Profile</m.Item></m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    assert.dom(menu.trigger).isDisabled().hasAttribute('data-disabled')
    // A disabled button hears nothing from a user; sent anyway, the events open nothing.
    const init = { bubbles: true, cancelable: true, button: 0, pointerType: 'mouse' }
    menu.trigger.dispatchEvent(new PointerEvent('pointerdown', init))
    menu.trigger.dispatchEvent(new KeyboardEvent('keydown', { ...init, key: 'Enter' }))
    await settled()
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('its yields: isOpen, open, close, toggle and setOpen, and an Arrow', async function (assert) {
    await render(
      <template>
        <DropdownMenu as |m|>
          <m.Trigger>Account</m.Trigger>
          <button type="button" class="open" {{on "click" m.open}}>open</button>
          <span class="state">{{if m.isOpen "open" "closed"}}</span>
          <m.Content class="dm-content">
            <m.Item>Profile</m.Item>
            <button type="button" class="close" {{on "click" (fn m.setOpen false)}}>close</button>
            <m.Arrow class="arrow" />
          </m.Content>
        </DropdownMenu>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await click('.open')
    assert.dom('.state').hasText('open')
    assert.dom('svg.arrow', menu.content).exists()
    await click('.close')
    assert.dom('.state').hasText('closed')
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})

module('Integration | primitives | dropdown-menu, Floating UI', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)

  placementTests(hooks)
})
