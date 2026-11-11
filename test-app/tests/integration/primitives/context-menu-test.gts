import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { focus, render, settled } from '@ember/test-helpers'
import { fn } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenu } from '@ember-joinery/primitives/context-menu'
import { isScrollLocked } from '@ember-joinery/primitives/scroll-lock'
import {
  ContextMenuHarness,
  pressKey,
  setupAnchorFallback,
  type TestHooks,
} from '@ember-joinery/test-support'

const Styles = <template>
  <style>
    .cm-area {
      position: fixed;
      top: 100px;
      left: 100px;
      display: block;
      width: 300px;
      height: 150px;
    }
    .cm-content {
      width: 160px;
      margin: 0;
      padding: 0;
      border: 0;
      overflow: visible;
    }
    .cm-content [role^="menuitem"] {
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
  @tracked checked = true
  changes: unknown[] = []
  selected: string[] = []
  onOpenChange = (open: boolean) => this.changes.push(open)
  setChecked = (checked: boolean) => (this.checked = checked)
  select = (name: string) => this.selected.push(name)
}

function placementTests(hooks: TestHooks) {
  void hooks

  test('it opens where the pointer is: to its right, level with it, 2px off', async function (assert) {
    await render(
      <template>
        <Styles />
        <ContextMenu as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
          <c.Content class="cm-content">
            <c.Item>Back</c.Item>
            <c.Item>Reload</c.Item>
          </c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await menu.open({ x: 150, y: 120 })
    const content = rect(menu.content!)
    near(assert, content.left, 152, 'its start 2px right of the pointer')
    near(assert, content.top, 120, 'its top level with the pointer')
    assert.strictEqual(menu.side, 'right')
    assert.strictEqual(menu.align, 'start')

    await menu.open({ x: 250, y: 200 })
    assert.true(menu.isOpen)
    near(assert, rect(menu.content!).left, 252, 'a right click while open moves it')
    near(assert, rect(menu.content!).top, 200, 'down too')
    await a11yAudit()
  })
}

module('Integration | primitives | context-menu', function (hooks) {
  setupRenderingTest(hooks)

  placementTests(hooks)

  test('a right click opens it in place of the browser’s menu, with focus on the menu', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Styles />
        <ContextMenu @name="page" @onOpenChange={{state.onOpenChange}} as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
          <c.Content class="cm-content">
            <c.Group>
              <c.Item>Back</c.Item>
              <c.Item @disabled={{true}}>Forward</c.Item>
              <c.Item @onSelect={{fn state.select "reload"}}>Reload</c.Item>
            </c.Group>
          </c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness('page')
    assert.dom(menu.trigger).hasTagName('span').hasAttribute('data-state', 'closed')
    assert.strictEqual(menu.content, null)

    const contextmenu = new MouseEvent('contextmenu', { bubbles: true, cancelable: true })
    menu.trigger.dispatchEvent(contextmenu)
    await settled()
    assert.true(contextmenu.defaultPrevented, 'the browser’s own menu doesn’t show')
    assert.true(menu.isOpen)
    assert.true(menu.isShown, 'in the top layer')
    assert.deepEqual(state.changes, [true])
    assert.dom(menu.trigger).hasAttribute('data-state', 'open')
    assert
      .dom(menu.content)
      .hasAttribute('role', 'menu')
      .hasAttribute('data-state', 'open')
      .doesNotHaveAttribute('aria-labelledby', 'nothing names it, as in Radix')
      .isFocused()
    assert.deepEqual(menu.items, ['Back', 'Forward', 'Reload'])
    assert.true(menu.isDisabled('Forward'))
    await a11yAudit()

    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Back')
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'Reload', 'past the disabled item')
    await pressKey('Enter')
    assert.deepEqual(state.selected, ['reload'])
    assert.false(menu.isOpen)
    assert.deepEqual(state.changes, [true, false])
    await a11yAudit()
  })

  test('Escape closes it, and focus goes back where it was', async function (assert) {
    await render(
      <template>
        <Styles />
        <button type="button" class="before">Before</button>
        <ContextMenu as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
          <c.Content class="cm-content"><c.Item>Back</c.Item></c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await focus('.before')
    await menu.open()
    assert.true(menu.isOpen)
    await menu.pressEscape()
    assert.false(menu.isOpen)
    assert.dom('.before').isFocused()
    await menu.open()
    await menu.select('Back')
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('a long press by touch or pen opens it; moving first, or a mouse, doesn’t', async function (assert) {
    await render(
      <template>
        <Styles />
        <ContextMenu as |c|>
          <c.Trigger class="cm-area">Long press here</c.Trigger>
          <c.Content class="cm-content"><c.Item>Back</c.Item></c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await menu.longPress({ x: 160, y: 140 })
    assert.true(menu.isOpen, 'a touch held for 700ms')
    near(assert, rect(menu.content!).left, 162, 'at the touch')
    await menu.pressEscape()
    await menu.longPress(undefined, { pointerType: 'pen' })
    assert.true(menu.isOpen, 'a pen')
    await menu.pressEscape()

    const init = { bubbles: true, clientX: 160, clientY: 140, pointerId: 1 }
    menu.trigger.dispatchEvent(new PointerEvent('pointerdown', { ...init, pointerType: 'touch' }))
    menu.trigger.dispatchEvent(new PointerEvent('pointermove', { ...init, pointerType: 'touch' }))
    await settled()
    assert.false(menu.isOpen, 'a touch that moves is a scroll')
    menu.trigger.dispatchEvent(new PointerEvent('pointerdown', { ...init, pointerType: 'mouse' }))
    await settled()
    assert.false(menu.isOpen, 'a mouse held down opens nothing')
    await a11yAudit()
  })

  test('a disabled trigger leaves the browser’s menu alone', async function (assert) {
    await render(
      <template>
        <Styles />
        <ContextMenu as |c|>
          <c.Trigger class="cm-area" @disabled={{true}}>Right click here</c.Trigger>
          <c.Content class="cm-content"><c.Item>Back</c.Item></c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness()
    assert.dom(menu.trigger).hasAttribute('data-disabled')
    const contextmenu = new MouseEvent('contextmenu', { bubbles: true, cancelable: true })
    menu.trigger.dispatchEvent(contextmenu)
    await settled()
    assert.false(contextmenu.defaultPrevented)
    assert.false(menu.isOpen)
    await a11yAudit()
  })

  test('modal (the default) or not, as a dropdown menu', async function (assert) {
    await render(
      <template>
        <Styles />
        <p class="page">The page</p>
        <ContextMenu as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
          <c.Content class="cm-content"><c.Item>Back</c.Item></c.Content>
        </ContextMenu>
        <ContextMenu @name="plain" @modal={{false}} as |c|>
          <c.Trigger class="cm-area" style="top: 300px">Or here</c.Trigger>
          <c.Content class="cm-content"><c.Item>Back</c.Item></c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.strictEqual(document.body.style.pointerEvents, 'none')
    assert.true(isScrollLocked())
    assert.dom('.page').hasAttribute('inert')
    await menu.pressEscape()
    const plain = new ContextMenuHarness('plain')
    await plain.open()
    assert.strictEqual(document.body.style.pointerEvents, '')
    assert.false(isScrollLocked())
    assert.dom('.page').doesNotHaveAttribute('inert')
    await plain.pressOutside()
    assert.false(plain.isOpen)
    await a11yAudit()
  })

  test('its checkbox items, radio items and submenus work as a dropdown menu’s', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Styles />
        <ContextMenu as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
          <c.Content class="cm-content">
            <c.Sub as |s|>
              <s.Trigger>More Tools</s.Trigger>
              <s.Content class="cm-content"><c.Item>Save Page...</c.Item></s.Content>
            </c.Sub>
            <c.Separator />
            <c.CheckboxItem @checked={{state.checked}} @onCheckedChange={{state.setChecked}}>
              Show Bookmarks
            </c.CheckboxItem>
            <c.RadioGroup @value="pedro" as |g|>
              <c.Label>People</c.Label>
              <g.Item @value="pedro">Pedro Duarte</g.Item>
              <g.Item @value="colm">Colm Tuite</g.Item>
            </c.RadioGroup>
          </c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, ['More Tools', 'Show Bookmarks', 'Pedro Duarte', 'Colm Tuite'])
    assert.deepEqual(menu.labels, ['People'])
    assert.true(menu.isChecked('Show Bookmarks'))
    assert.true(menu.isChecked('Pedro Duarte'))
    const sub = menu.sub('More Tools')
    await sub.open()
    assert.deepEqual(sub.items, ['Save Page...'])
    assert.strictEqual(sub.side, 'right')
    await a11yAudit()
    await menu.select('Show Bookmarks')
    assert.false(state.checked)
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})

module('Integration | primitives | context-menu, Floating UI', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)

  placementTests(hooks)
})
