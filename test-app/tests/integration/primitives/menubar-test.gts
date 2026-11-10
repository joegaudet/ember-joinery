import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { focus, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Menubar } from '@ember-joinery/primitives/menubar'
import { MenubarHarness, pressKey, tab } from '@ember-joinery/test-support'

/** Fixed sizes and none of the browser's popover styles, so edges line up. */
const Styles = <template>
  <style>
    .mb-stage {
      position: fixed;
      top: 100px;
      left: 200px;
    }
    .mb-bar {
      display: flex;
    }
    .mb-trigger {
      width: 60px;
      height: 24px;
      padding: 0;
      border: 0;
    }
    .mb-content {
      width: 160px;
      margin: 0;
      padding: 0;
      border: 0;
      overflow: visible;
    }
    .mb-content [role^="menuitem"] {
      height: 24px;
    }
  </style>
</template>

class State {
  @tracked value = ''
  @tracked bookmarks = false
  @tracked person = 'benoit'
  changes: string[] = []
  selected: string[] = []
  setValue = (value: string) => {
    this.changes.push(value)
    this.value = value
  }
  setBookmarks = (checked: boolean) => (this.bookmarks = checked)
  setPerson = (person: string) => (this.person = person)
  select = (name: string) => () => this.selected.push(name)
}

/** A three-menu bar: File (with a Share submenu), Edit (Cut disabled), View, as upstream's demo. */
const Bar = <template>
  <Styles />
  <div class="mb-stage">
    <Menubar
      class="mb-bar"
      @value={{@state.value}}
      @onValueChange={{@state.setValue}}
      @loop={{@loop}}
      @name="app"
      as |bar|
    >
      <bar.Menu @value="file" as |m|>
        <m.Trigger class="mb-trigger">File</m.Trigger>
        <m.Content class="mb-content">
          <m.Item @onSelect={{@state.select "new-tab"}}>New Tab</m.Item>
          <m.Item>New Window</m.Item>
          <m.Separator />
          <m.Sub as |s|>
            <s.Trigger>Share</s.Trigger>
            <s.Content class="mb-content">
              <m.Item>Email link</m.Item>
              <m.Item>Messages</m.Item>
            </s.Content>
          </m.Sub>
          <m.Item>Print...</m.Item>
        </m.Content>
      </bar.Menu>
      <bar.Menu @value="edit" as |m|>
        <m.Trigger class="mb-trigger" @disabled={{@editDisabled}}>Edit</m.Trigger>
        <m.Content class="mb-content">
          <m.Item>Undo</m.Item>
          <m.Item @disabled={{true}}>Cut</m.Item>
          <m.Item>Paste</m.Item>
        </m.Content>
      </bar.Menu>
      <bar.Menu @value="view" as |m|>
        <m.Trigger class="mb-trigger">View</m.Trigger>
        <m.Content class="mb-content">
          <m.CheckboxItem
            @checked={{@state.bookmarks}}
            @onCheckedChange={{@state.setBookmarks}}
          >Bookmarks Bar</m.CheckboxItem>
          <m.RadioGroup @value={{@state.person}} @onValueChange={{@state.setPerson}} as |g|>
            <g.Item @value="andy">Andy</g.Item>
            <g.Item @value="benoit">Benoit</g.Item>
          </m.RadioGroup>
        </m.Content>
      </bar.Menu>
    </Menubar>
  </div>
</template>

module('Integration | primitives | menubar', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a menubar of menuitem triggers, one tab stop between them', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness('app')
    assert.dom(menubar.element).hasAttribute('role', 'menubar')
    assert.dom(menubar.element).hasAttribute('data-orientation', 'horizontal')
    assert.deepEqual(menubar.menus, ['File', 'Edit', 'View'])
    for (const trigger of menubar.triggers) {
      assert
        .dom(trigger)
        .hasTagName('button')
        .hasAttribute('type', 'button')
        .hasAttribute('role', 'menuitem')
        .hasAttribute('aria-haspopup', 'menu')
        .hasAttribute('aria-expanded', 'false')
        .doesNotHaveAttribute('aria-controls')
        .hasAttribute('data-state', 'closed')
        .hasAttribute('tabindex', '-1')
    }
    assert.dom(menubar.element).hasAttribute('tabindex', '0', 'Tab enters on the bar')
    await a11yAudit()

    await tab()
    assert.strictEqual(menubar.focusedTrigger, 'File', 'Tab goes on to the first trigger')
    assert.strictEqual(menubar.tabStop, 'File')
    assert.dom(menubar.trigger('File')).hasAttribute('data-highlighted', '')
    await a11yAudit()
  })

  test('a press opens a menu, labelled by its trigger; a press on it again closes it', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness('app')
    const file = menubar.menu('File')
    await file.open()
    assert.true(file.isOpen)
    assert.strictEqual(state.value, 'file', 'the menubar’s value is the menu’s')
    assert.strictEqual(menubar.openMenu, 'File')
    assert.true(file.isShown, 'in the top layer')
    assert.dom(file.content).hasAttribute('role', 'menu').hasAttribute('data-state', 'open')
    assert.dom(file.content).hasAttribute('data-test-jn-owner', menubar.element.id)
    assert.dom(file.trigger).hasAttribute('aria-controls', file.content!.id)
    assert.dom(file.trigger).hasAttribute('data-state', 'open')
    assert.strictEqual(file.label, 'File')
    assert.deepEqual(file.items, ['New Tab', 'New Window', 'Share', 'Print...'])
    assert.dom(file.content).isFocused('focus goes to the menu, not an item')
    assert.strictEqual(menubar.tabStop, 'File')
    await a11yAudit()

    await file.toggle()
    assert.false(file.isOpen)
    assert.deepEqual(state.changes, ['file', ''])
    assert.dom(file.trigger).isFocused('focus goes back to its trigger')
    await a11yAudit()
  })

  test('below its trigger, at its start, touching it', async function (assert) {
    const state = new State()
    state.value = 'edit'
    await render(<template><Bar @state={{state}} /></template>)
    const edit = new MenubarHarness().menu('Edit')
    const t = edit.trigger.getBoundingClientRect()
    const c = edit.content!.getBoundingClientRect()
    assert.true(Math.abs(c.top - t.bottom) <= 1, 'touching the trigger')
    assert.true(Math.abs(c.left - t.left) <= 1, 'lined up with its start')
    assert.strictEqual(edit.side, 'bottom')
    assert.strictEqual(edit.align, 'start')
    await a11yAudit()
  })

  test('the arrow keys move between the triggers, round from the last to the first', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness()
    await focus(menubar.trigger('File'))
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.focusedTrigger, 'Edit')
    assert.strictEqual(menubar.tabStop, 'Edit', 'the tab stop moves along')
    await pressKey('ArrowRight')
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.focusedTrigger, 'File', 'round to the first')
    await pressKey('ArrowLeft')
    assert.strictEqual(menubar.focusedTrigger, 'View', 'and back to the last')
    await pressKey('Home')
    assert.strictEqual(menubar.focusedTrigger, 'File')
    await pressKey('End')
    assert.strictEqual(menubar.focusedTrigger, 'View')
    assert.false(menubar.isOpen, 'they open nothing')
    await a11yAudit()
  })

  test('Enter, Space and ArrowDown open a menu with its first item focused; Escape closes it', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness()
    const file = menubar.menu('File')
    for (const key of ['Enter', ' ', 'ArrowDown'] as const) {
      await file.openWithKeyboard(key)
      assert.true(file.isOpen, `${key === ' ' ? 'Space' : key} opens it`)
      assert.strictEqual(file.highlighted, 'New Tab', 'its first item has focus')
      await pressKey('ArrowDown')
      assert.strictEqual(file.highlighted, 'New Window')
      await menubar.pressEscape()
      assert.false(file.isOpen)
      assert.dom(file.trigger).isFocused('Escape puts focus back on the trigger')
    }
    await file.openWithKeyboard('Enter')
    await pressKey('Tab')
    assert.true(file.isOpen, 'Tab stays in the menu')
    await a11yAudit()
  })

  test('in an open menu, ArrowRight and ArrowLeft open the next and previous menus', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness()
    await menubar.menu('File').openWithKeyboard()
    await pressKey('ArrowRight')
    const edit = menubar.menu('Edit')
    assert.strictEqual(menubar.openMenu, 'Edit')
    assert.dom(edit.content).isFocused('focus is on the menu, as Radix’s: no item yet')
    assert.strictEqual(menubar.tabStop, 'Edit')
    await pressKey('ArrowDown')
    assert.strictEqual(edit.highlighted, 'Undo')
    await pressKey('ArrowDown')
    assert.strictEqual(edit.highlighted, 'Paste', 'past the disabled item')
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'View')
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'File', 'round to the first')
    await pressKey('ArrowLeft')
    assert.strictEqual(menubar.openMenu, 'View', 'and back')
    assert.deepEqual(state.changes, ['file', 'edit', 'view', 'file', 'view'])
    await menubar.pressEscape()
    assert.dom(menubar.trigger('View')).isFocused('Escape closes it, focus on its trigger')
    await a11yAudit()
  })

  test('with @loop false, the arrows stop at the ends', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} @loop={{false}} /></template>)
    const menubar = new MenubarHarness()
    await menubar.menu('View').openWithKeyboard()
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'View', 'no menu after the last')
    await menubar.pressEscape()
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.focusedTrigger, 'View', 'the triggers stop too')
    await a11yAudit()
  })

  test('a disabled trigger opens nothing, and the arrows skip it', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} @editDisabled={{true}} /></template>)
    const menubar = new MenubarHarness()
    const edit = menubar.menu('Edit')
    assert.dom(edit.trigger).isDisabled().hasAttribute('data-disabled', '')
    assert.true(edit.isTriggerDisabled)
    await focus(menubar.trigger('File'))
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.focusedTrigger, 'View', 'past Edit')
    await menubar.menu('File').openWithKeyboard()
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'View', 'past Edit')
    await a11yAudit()
  })

  test('the arrow into a submenu opens it; the arrow back closes only the submenu', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness()
    const file = menubar.menu('File')
    await file.openWithKeyboard()
    await pressKey('ArrowDown')
    await pressKey('ArrowDown')
    assert.strictEqual(file.highlighted, 'Share')
    await pressKey('ArrowRight')
    const share = file.sub('Share')
    assert.true(share.isOpen, 'ArrowRight on its trigger opens the submenu')
    assert.strictEqual(menubar.openMenu, 'File', 'not the next menu')
    assert.strictEqual(share.highlighted, 'Email link')
    await a11yAudit()
    await pressKey('ArrowLeft')
    assert.false(share.isOpen, 'ArrowLeft closes the submenu')
    assert.strictEqual(menubar.openMenu, 'File', 'and only the submenu')
    assert.strictEqual(file.highlighted, 'Share')
    await pressKey('ArrowRight')
    assert.strictEqual(share.highlighted, 'Email link')
    await pressKey('ArrowRight')
    assert.strictEqual(
      menubar.openMenu,
      'Edit',
      'ArrowRight on a submenu’s item opens the next menu',
    )
    await a11yAudit()
  })

  test('while a menu is open, the pointer opens the menu whose trigger it rests on', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness()
    await menubar.menu('View').hoverTrigger()
    assert.false(menubar.isOpen, 'not while every menu is closed')
    await menubar.menu('File').open()
    await menubar.menu('View').hoverTrigger()
    assert.strictEqual(menubar.openMenu, 'View')
    assert.dom(menubar.menu('View').content).isFocused()
    await menubar.menu('View').toggle()
    assert.false(menubar.isOpen, 'a press on its trigger then closes it')
    await a11yAudit()
  })

  test('a press on another trigger, or outside, while a menu is open', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness()
    await menubar.menu('File').open()
    await menubar.menu('Edit').toggle()
    assert.strictEqual(menubar.openMenu, 'Edit', 'a touch on another trigger opens that one')
    await menubar.pressOutside()
    assert.false(menubar.isOpen, 'a press outside closes it')
    assert.dom(menubar.trigger('Edit')).isNotFocused('focus stays where the user put it')
    await a11yAudit()
  })

  test('selecting an item closes the menu and puts focus back on its trigger', async function (assert) {
    const state = new State()
    await render(<template><Bar @state={{state}} /></template>)
    const menubar = new MenubarHarness()
    const file = menubar.menu('File')
    await file.openWithKeyboard()
    await pressKey('Enter')
    assert.deepEqual(state.selected, ['new-tab'])
    assert.false(menubar.isOpen)
    assert.dom(file.trigger).isFocused()

    const view = menubar.menu('View')
    await view.open()
    assert.strictEqual(view.role('Bookmarks Bar'), 'menuitemcheckbox')
    assert.false(view.isChecked('Bookmarks Bar'))
    await view.select('Bookmarks Bar')
    assert.true(state.bookmarks)
    await view.open()
    assert.true(view.isChecked('Bookmarks Bar'))
    assert.true(view.isChecked('Benoit'))
    await view.select('Andy')
    assert.strictEqual(state.person, 'andy')
    await a11yAudit()
  })

  test('uncontrolled: @defaultValue opens a menu at first, and @onValueChange hears each change', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Styles />
        <Menubar @defaultValue="b" @onValueChange={{state.setValue}} as |bar|>
          <bar.Menu @value="a" as |m|>
            <m.Trigger>A</m.Trigger>
            <m.Content class="mb-content"><m.Item>One</m.Item></m.Content>
          </bar.Menu>
          <bar.Menu @value="b" as |m|>
            <m.Trigger>B</m.Trigger>
            <m.Content class="mb-content"><m.Item>Two</m.Item></m.Content>
          </bar.Menu>
        </Menubar>
      </template>,
    )
    const menubar = new MenubarHarness()
    assert.strictEqual(menubar.openMenu, 'B')
    await menubar.menu('A').hoverTrigger()
    assert.strictEqual(menubar.openMenu, 'A')
    await menubar.pressEscape()
    assert.deepEqual(state.changes, ['a', ''])
    await a11yAudit()
  })

  test('a menu without @value gets one of its own', async function (assert) {
    await render(
      <template>
        <Styles />
        <Menubar as |bar|>
          <bar.Menu as |m|>
            <m.Trigger>A</m.Trigger>
            <m.Content class="mb-content"><m.Item>One</m.Item></m.Content>
          </bar.Menu>
        </Menubar>
      </template>,
    )
    const menubar = new MenubarHarness()
    const a = menubar.menu('A')
    assert.ok(a.trigger.getAttribute('data-test-jn-value'), 'a value of its own')
    await a.open()
    assert.true(a.isOpen)
    await a11yAudit()
  })

  test('your own element as a trigger, with the trigger modifier', async function (assert) {
    await render(
      <template>
        <Styles />
        <Menubar as |bar|>
          <bar.Menu as |m|>
            <button class="mb-trigger" {{m.trigger}}>Mine</button>
            <m.Content class="mb-content"><m.Item>One</m.Item></m.Content>
          </bar.Menu>
        </Menubar>
      </template>,
    )
    const menubar = new MenubarHarness()
    const mine = menubar.menu('Mine')
    assert.dom(mine.trigger).hasAttribute('role', 'menuitem').hasAttribute('type', 'button')
    await mine.openWithKeyboard()
    assert.strictEqual(mine.highlighted, 'One')
    await a11yAudit()
  })

  test('right to left, ArrowLeft goes to the next trigger and opens the next menu', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DirectionProvider @dir="rtl"><Bar @state={{state}} /></DirectionProvider>
      </template>,
    )
    const menubar = new MenubarHarness()
    await focus(menubar.trigger('File'))
    await pressKey('ArrowLeft')
    assert.strictEqual(menubar.focusedTrigger, 'Edit')
    await menubar.menu('File').openWithKeyboard()
    await pressKey('ArrowLeft')
    assert.strictEqual(menubar.openMenu, 'Edit')
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'File')
    await pressKey('ArrowDown')
    await pressKey('ArrowDown')
    await pressKey('ArrowDown')
    await pressKey('ArrowLeft')
    const share = menubar.menu('File').sub('Share')
    assert.true(share.isOpen, 'ArrowLeft opens a submenu right to left')
    assert.strictEqual(share.side, 'left')
    await settled()
    await a11yAudit()
  })
})
