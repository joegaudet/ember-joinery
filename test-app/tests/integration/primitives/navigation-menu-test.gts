import { module, test } from 'qunit'
import type { TOC } from '@ember/component/template-only'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { focus, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { NavigationMenu } from '@ember-joinery/primitives/navigation-menu'
import {
  NavigationMenuHarness,
  hover,
  press,
  pressKey,
  tab,
  unhover,
} from '@ember-joinery/test-support'

/** Fixed sizes, so the viewport's size and the indicator's place can be checked. */
const Styles = <template>
  <style>
    .nm-root {
      position: relative;
    }
    .nm-list {
      display: flex;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    .nm-trigger,
    .nm-list > li > a {
      display: block;
      width: 100px;
      height: 30px;
      padding: 0;
      border: 0;
    }
    .nm-content {
      position: absolute;
      top: 0;
      left: 0;
    }
    .nm-content a {
      display: block;
      height: 20px;
    }
    .nm-viewport {
      position: relative;
      width: var(--radix-navigation-menu-viewport-width);
      height: var(--radix-navigation-menu-viewport-height);
    }
  </style>
</template>

class State {
  @tracked value = ''
  changes: string[] = []
  selected: string[] = []
  setValue = (value: string) => {
    this.changes.push(value)
    this.value = value
  }
  select = (name: string) => () => this.selected.push(name)
  keepOpen = (event: Event) => event.preventDefault()
}

/** Two items with contents (one 200 wide, one 300), a plain link, a viewport and an indicator. */
const Menu: TOC<{ Args: { state: State } }> = <template>
  <Styles />
  <NavigationMenu
    class="nm-root"
    @value={{@state.value}}
    @onValueChange={{@state.setValue}}
    @name="site"
    as |n|
  >
    <n.List class="nm-list">
      <n.Item @value="start" as |item|>
        <item.Trigger class="nm-trigger">Getting started</item.Trigger>
        <item.Content class="nm-content" style="width: 200px">
          <n.Link href="#intro" @onSelect={{@state.select "intro"}}>Introduction</n.Link>
          <n.Link href="#install">Installation</n.Link>
        </item.Content>
      </n.Item>
      <n.Item @value="components" as |item|>
        <item.Trigger class="nm-trigger">Components</item.Trigger>
        <item.Content class="nm-content" style="width: 300px">
          <n.Link href="#alert" @onSelect={{@state.keepOpen}}>Alert Dialog</n.Link>
          <n.Link href="#tabs">Tabs</n.Link>
        </item.Content>
      </n.Item>
      <n.Item>
        <n.Link href="#docs" @active={{true}}>Docs</n.Link>
      </n.Item>
    </n.List>
    <n.Indicator class="nm-indicator" />
    <n.Viewport class="nm-viewport" />
  </NavigationMenu>
</template>

module('Integration | primitives | navigation-menu', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a nav, its list and items, and triggers that control their contents', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness('site')
    assert.dom(nav.element).hasTagName('nav').hasAttribute('aria-label', 'Main')
    assert.dom(nav.element).hasAttribute('data-orientation', 'horizontal')
    assert.dom(nav.list).hasTagName('ul').hasAttribute('data-orientation', 'horizontal')
    assert.strictEqual(
      nav.list.parentElement!.style.position,
      'relative',
      'in the indicator’s track',
    )
    assert.dom('li', nav.list).exists({ count: 3 })
    assert.deepEqual(nav.triggerLabels, ['Getting started', 'Components'])
    assert.deepEqual(nav.listLinks, ['Docs'])
    const start = nav.item('Getting started')
    assert
      .dom(start.trigger)
      .hasTagName('button')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('data-state', 'closed')
      .hasAttribute('aria-controls', `${nav.element.id}-content-start`)
      .hasAttribute('id', `${nav.element.id}-trigger-start`)
    assert.strictEqual(start.content, null, 'its content isn’t rendered while closed')
    assert.strictEqual(nav.viewport, null, 'nor is the viewport')
    assert
      .dom(nav.listLink('Docs'))
      .hasAttribute('aria-current', 'page')
      .hasAttribute('data-active', '')
    await a11yAudit()
  })

  test('a click opens a content in the viewport, sized to it; another click closes it', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.toggle()
    assert.true(start.isOpen)
    assert.strictEqual(state.value, 'start')
    assert.dom(start.trigger).hasAttribute('data-state', 'open')
    const viewport = nav.viewport!
    assert.dom(viewport).hasAttribute('data-state', 'open')
    assert.ok(viewport.contains(start.content), 'the content shows in the viewport')
    assert.dom(start.content).hasAttribute('aria-labelledby', start.trigger.id)
    assert.dom(start.content).doesNotHaveAttribute('data-state', 'as Radix’s, in a viewport')
    assert.dom(start.content).doesNotHaveAttribute('data-motion', 'opening from closed: no motion')
    assert.deepEqual(start.links, ['Introduction', 'Installation'])
    assert.deepEqual(nav.viewportSize, { width: 200, height: 40 })
    assert.strictEqual(start.label, 'Getting started')
    assert
      .dom(`[aria-owns="${start.content!.id}"]`, nav.element)
      .exists('the content is owned after its trigger, for assistive technology')
    await a11yAudit()

    await start.toggle()
    assert.false(start.isOpen)
    assert.strictEqual(nav.viewport, null)
    assert.deepEqual(state.changes, ['start', ''])
    await a11yAudit()
  })

  test('switching contents: each slides from the side of the trigger it replaces', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    const components = nav.item('Components')
    await start.open()
    await components.open()
    assert.strictEqual(components.motion, 'from-end', 'from the end: its trigger is after')
    assert.deepEqual(nav.viewportSize, { width: 300, height: 40 }, 'resized to the new content')
    await start.open()
    assert.strictEqual(start.motion, 'from-start')
    await a11yAudit()
  })

  test('the pointer opens a content after a delay, at once while another was just open, and closes it on leaving', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    const components = nav.item('Components')
    const begun = performance.now()
    await start.hover()
    assert.true(start.isOpen)
    assert.true(performance.now() - begun >= 190, 'after the 200ms delay')
    await unhover(start.trigger, { side: 'right' })
    const moved = performance.now()
    await hover(components.trigger)
    assert.true(components.isOpen, 'moving to another trigger opens it')
    assert.true(performance.now() - moved < 150, 'at once, as one had just been open')
    await unhover(components.trigger, { side: 'top' })
    assert.false(nav.isOpen, 'leaving both closes it')
    await a11yAudit()
  })

  test('the pointer on the viewport keeps the content open', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.hover()
    // Off the trigger and straight onto the viewport, before the close delay is up.
    const mouse = { pointerType: 'mouse', bubbles: false }
    start.trigger.dispatchEvent(new PointerEvent('pointerleave', mouse))
    nav.viewport!.dispatchEvent(new PointerEvent('pointerenter', mouse))
    await settled()
    assert.true(start.isOpen, 'the pointer is on its way into it')
    await unhover(nav.viewport!, { side: 'bottom' })
    assert.false(start.isOpen)
    await a11yAudit()
  })

  test('a link closes the content it is in, unless its @onSelect prevents it', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.open()
    await start.select('Introduction')
    assert.deepEqual(state.selected, ['intro'])
    assert.false(start.isOpen)
    const components = nav.item('Components')
    await components.open()
    await components.select('Alert Dialog')
    assert.true(components.isOpen, 'prevented')
    await a11yAudit()
  })

  test('Tab goes from an open trigger into its content, and out to the next trigger', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.openWithKeyboard()
    assert.true(start.isOpen, 'Enter opens it')
    assert.dom(start.trigger).isFocused('focus stays on the trigger')
    await tab()
    assert.strictEqual(nav.focused, 'Introduction', 'Tab goes into the content')
    await tab()
    assert.strictEqual(nav.focused, 'Installation')
    await tab()
    assert.strictEqual(nav.focused, 'Components', 'and out to the next trigger')
    assert.true(start.isOpen)
    await tab({ shift: true })
    assert.strictEqual(
      nav.focused,
      'Installation',
      'Shift+Tab goes back into the content, at its end',
    )
    await a11yAudit()
  })

  test('a trigger of your own, with the modifier, has the focus proxy and aria-owns too', async function (assert) {
    await render(
      <template>
        <Styles />
        <NavigationMenu class="nm-root" as |n|>
          <n.List class="nm-list">
            <n.Item @value="start" as |item|>
              <button type="button" class="nm-trigger" {{item.trigger}}>Getting started</button>
              <item.Content class="nm-content">
                <n.Link href="#intro">Introduction</n.Link>
                <n.Link href="#install">Installation</n.Link>
              </item.Content>
            </n.Item>
            <n.Item @value="components" as |item|>
              <item.Trigger class="nm-trigger">Components</item.Trigger>
              <item.Content class="nm-content"><n.Link href="#tabs">Tabs</n.Link></item.Content>
            </n.Item>
          </n.List>
          <n.Viewport class="nm-viewport" />
        </NavigationMenu>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.openWithKeyboard()
    await settled()
    assert.true(start.isOpen)
    const item = start.trigger.closest('li')!
    assert
      .dom('[data-test-jn-part="focus-proxy"]', item)
      .exists({ count: 1 }, 'the item renders the proxy, after the trigger')
    assert
      .dom(`[aria-owns="${start.content!.id}"]`, item)
      .exists('and owns the content after it, for assistive technology')
    await tab()
    assert.strictEqual(nav.focused, 'Introduction', 'Tab goes into the content')
    await tab()
    await tab()
    assert.strictEqual(nav.focused, 'Components', 'and out to the next trigger')
    await tab({ shift: true })
    assert.strictEqual(nav.focused, 'Installation', 'Shift+Tab goes back in, at its end')
    await a11yAudit()

    await nav.item('Components').open()
    assert
      .dom('[data-test-jn-part="focus-proxy"]', nav.element)
      .exists({ count: 1 }, 'only the open trigger’s, which its Trigger renders')
    assert.strictEqual(
      nav.trigger('Components').nextElementSibling?.getAttribute('data-test-jn-part'),
      'focus-proxy',
      'right after it',
    )
    await a11yAudit()
  })

  test('without a viewport, Tab goes through a modifier trigger’s content and on', async function (assert) {
    await render(
      <template>
        <Styles />
        <NavigationMenu as |n|>
          <n.List class="nm-list">
            <n.Item as |item|>
              <button type="button" class="nm-trigger" {{item.trigger}}>Learn</button>
              <item.Content class="nm-content">
                <n.Link href="#a">A</n.Link>
                <n.Link href="#b">B</n.Link>
              </item.Content>
            </n.Item>
            <n.Item><n.Link href="#docs">Docs</n.Link></n.Item>
          </n.List>
        </NavigationMenu>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    const learn = nav.item('Learn')
    for (const round of ['first', 'second']) {
      await learn.openWithKeyboard()
      await settled()
      assert.dom(`[aria-owns]`, nav.element).doesNotExist('nothing to re-parent')
      await tab()
      assert.strictEqual(nav.focused, 'A', `${round} time: Tab goes into the content`)
      await tab()
      await tab()
      assert.strictEqual(nav.focused, 'Docs', 'and on past it')
      await tab({ shift: true })
      assert.strictEqual(nav.focused, 'B', 'Shift+Tab goes back in, at its end')
      await nav.pressEscape()
      assert.false(learn.isOpen)
    }
    await a11yAudit()
  })

  test('ArrowDown on an open trigger enters its content; the arrows move between triggers and links', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await focus(start.trigger)
    await pressKey('ArrowRight')
    assert.strictEqual(nav.focused, 'Components')
    await pressKey('ArrowRight')
    assert.strictEqual(nav.focused, 'Docs')
    await pressKey('ArrowRight')
    assert.strictEqual(nav.focused, 'Docs', 'not round')
    await pressKey('Home')
    assert.strictEqual(nav.focused, 'Getting started')
    await pressKey('End')
    assert.strictEqual(nav.focused, 'Docs')
    await pressKey('ArrowLeft')
    assert.strictEqual(nav.focused, 'Components')
    await nav.item('Components').openWithKeyboard()
    await pressKey('ArrowDown')
    assert.strictEqual(nav.focused, 'Alert Dialog', 'ArrowDown enters the open content')
    await pressKey('ArrowDown')
    assert.strictEqual(nav.focused, 'Tabs', 'and moves between its links')
    await pressKey('ArrowUp')
    assert.strictEqual(nav.focused, 'Alert Dialog')
    await a11yAudit()
  })

  test('Escape closes the content, focus back on its trigger; the pointer then waits to leave', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.openWithKeyboard()
    await pressKey('ArrowDown')
    assert.strictEqual(nav.focused, 'Introduction')
    await nav.pressEscape()
    assert.false(start.isOpen)
    assert.dom(start.trigger).isFocused()
    // The pointer, resting on the trigger all along, moves a little.
    start.trigger.dispatchEvent(
      new PointerEvent('pointermove', { pointerType: 'mouse', bubbles: true }),
    )
    await settled()
    assert.false(start.isOpen, 'it doesn’t open it again until the pointer has left')
    await hover(start.trigger)
    assert.true(start.isOpen, 'coming back onto the trigger does')
    await a11yAudit()
  })

  test('a press outside closes it; a press on a trigger or in the viewport doesn’t', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.open()
    await press(nav.viewport!)
    assert.true(start.isOpen, 'not in the viewport')
    await press(nav.trigger('Components'))
    assert.strictEqual(nav.openItem, 'Components', 'a trigger opens its own')
    await nav.pressOutside()
    assert.false(nav.isOpen)
    await a11yAudit()
  })

  test('the indicator goes under the open trigger, as wide as it', async function (assert) {
    const state = new State()
    await render(<template><Menu @state={{state}} /></template>)
    const nav = new NavigationMenuHarness()
    assert.strictEqual(nav.indicator, null, 'not while nothing is open')
    await nav.item('Components').open()
    const indicator = nav.indicator!
    assert.dom(indicator).hasAttribute('data-state', 'visible').hasAttribute('aria-hidden', 'true')
    assert.strictEqual(indicator.parentElement, nav.list.parentElement, 'in the list’s track')
    assert.strictEqual(indicator.style.width, '100px')
    assert.strictEqual(indicator.style.transform, 'translateX(100px)')
    await nav.item('Getting started').open()
    assert.strictEqual(indicator.style.transform, 'translateX(0px)')
    await a11yAudit()
  })

  test('without a viewport, a content shows in its item, with data-state', async function (assert) {
    await render(
      <template>
        <Styles />
        <NavigationMenu as |n|>
          <n.List class="nm-list">
            <n.Item as |item|>
              <item.Trigger class="nm-trigger">Learn</item.Trigger>
              <item.Content class="nm-content"><n.Link href="#a">A</n.Link></item.Content>
            </n.Item>
          </n.List>
        </NavigationMenu>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    const learn = nav.item('Learn')
    await learn.open()
    assert.ok(learn.trigger.closest('li')!.contains(learn.content), 'in its item')
    assert.dom(learn.content).hasAttribute('data-state', 'open')
    assert.dom(`[aria-owns]`, nav.element).doesNotExist('nothing to re-parent')
    await a11yAudit()
  })

  test('uncontrolled, with @defaultValue; a link of your own with the link modifier', async function (assert) {
    await render(
      <template>
        <Styles />
        <NavigationMenu @defaultValue="learn" as |n|>
          <n.List class="nm-list">
            <n.Item @value="learn" as |item|>
              <item.Trigger class="nm-trigger">Learn</item.Trigger>
              <item.Content class="nm-content">
                <a href="#mine" {{n.link}}>Mine</a>
              </item.Content>
            </n.Item>
          </n.List>
          <n.Viewport class="nm-viewport" />
        </NavigationMenu>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    const learn = nav.item('Learn')
    assert.true(learn.isOpen)
    assert.deepEqual(learn.links, ['Mine'])
    await learn.select('Mine')
    assert.false(learn.isOpen)
    await a11yAudit()
  })

  test('vertical: ArrowRight on an open trigger enters its content, and the indicator moves down', async function (assert) {
    await render(
      <template>
        <Styles />
        <NavigationMenu @orientation="vertical" @defaultValue="b" as |n|>
          <n.List class="nm-list" style="flex-direction: column">
            <n.Item @value="a" as |item|>
              <item.Trigger class="nm-trigger">A</item.Trigger>
              <item.Content class="nm-content"><n.Link href="#a">Link A</n.Link></item.Content>
            </n.Item>
            <n.Item @value="b" as |item|>
              <item.Trigger class="nm-trigger">B</item.Trigger>
              <item.Content class="nm-content"><n.Link href="#b">Link B</n.Link></item.Content>
            </n.Item>
          </n.List>
          <n.Indicator />
          <n.Viewport class="nm-viewport" />
        </NavigationMenu>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    assert.dom(nav.element).hasAttribute('data-orientation', 'vertical')
    assert.dom(nav.list).hasAttribute('data-orientation', 'vertical')
    const b = nav.item('B')
    assert.true(b.isOpen)
    assert.dom(nav.indicator).hasAttribute('data-orientation', 'vertical')
    assert.strictEqual(nav.indicator!.style.height, '30px')
    assert.strictEqual(nav.indicator!.style.transform, 'translateY(30px)')
    await focus(nav.trigger('A'))
    await pressKey('ArrowDown')
    assert.strictEqual(nav.focused, 'B', 'ArrowDown moves on to the next trigger')
    await pressKey('ArrowRight')
    assert.strictEqual(nav.focused, 'Link B', 'ArrowRight enters the open content')
    await a11yAudit()
  })

  test('right to left, the arrows flip and the motion follows the triggers', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DirectionProvider @dir="rtl"><Menu @state={{state}} /></DirectionProvider>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    await focus(nav.trigger('Getting started'))
    await pressKey('ArrowLeft')
    assert.strictEqual(nav.focused, 'Components', 'ArrowLeft is next')
    await nav.item('Getting started').open()
    await nav.item('Components').open()
    assert.strictEqual(
      nav.item('Components').motion,
      'from-start',
      'its trigger is left of the other: from the left',
    )
    await a11yAudit()
  })
})
