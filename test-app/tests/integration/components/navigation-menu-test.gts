import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { NavigationMenu, navigationMenuTriggerStyle } from '@ember-joinery/ember'
import { NavigationMenuHarness, pressKey, tab } from '@ember-joinery/test-support'

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

/** Ends the running animations, so computed styles are the resting ones. */
function finishAnimations(element: Element) {
  for (const animation of element.getAnimations({ subtree: true })) animation.finish()
}

/** Upstream's demo, cut down: two triggers with contents of their own width, and a link. */
const Demo = <template>
  <NavigationMenu @viewport={{@viewport}} @name="site" as |n|>
    <n.List>
      <n.Item @value="start" as |item|>
        <item.Trigger>Getting started</item.Trigger>
        <item.Content>
          <ul style="width: 384px; margin: 0; padding: 0; list-style: none">
            <li><n.Link href="#intro">Introduction</n.Link></li>
            <li><n.Link href="#install">Installation</n.Link></li>
          </ul>
        </item.Content>
      </n.Item>
      <n.Item @value="components" as |item|>
        <item.Trigger>Components</item.Trigger>
        <item.Content>
          <ul style="width: 500px; margin: 0; padding: 0; list-style: none">
            <li><n.Link href="#alert">Alert Dialog</n.Link></li>
          </ul>
        </item.Content>
      </n.Item>
      <n.Item>
        <n.Link href="#docs" class={{(navigationMenuTriggerStyle)}}>Docs</n.Link>
      </n.Item>
    </n.List>
  </NavigationMenu>
</template>

module('Integration | components | navigation-menu', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream’s classes and slots, with a viewport', async function (assert) {
    await render(<template><Demo /></template>)
    const nav = new NavigationMenuHarness('site')
    assert
      .dom(nav.element)
      .hasClass('jn-navigation-menu')
      .hasClass('group/navigation-menu')
      .hasAttribute('data-slot', 'navigation-menu')
      .hasAttribute('data-viewport', 'true')
    assert
      .dom(nav.list)
      .hasClass('jn-navigation-menu-list')
      .hasClass('group')
      .hasAttribute('data-slot', 'navigation-menu-list')
    assert.dom('[data-slot="navigation-menu-item"]', nav.list).exists({ count: 3 })
    assert.dom('[data-slot="navigation-menu-item"]', nav.list).hasClass('jn-navigation-menu-item')
    const start = nav.item('Getting started')
    assert
      .dom(start.trigger)
      .hasClass('jn-navigation-menu-trigger')
      .hasClass('group/navigation-menu-trigger')
      .hasClass('group')
      .hasAttribute('data-slot', 'navigation-menu-trigger')
    assert
      .dom('svg.jn-navigation-menu-trigger-icon', start.trigger)
      .hasAttribute('aria-hidden', 'true')
    assert
      .dom(nav.listLink('Docs'))
      .hasClass('jn-navigation-menu-link')
      .hasClass('jn-navigation-menu-trigger', 'navigationMenuTriggerStyle() gives a link the look')
      .hasAttribute('data-slot', 'navigation-menu-link')
    assert.dom('.jn-navigation-menu-viewport-wrapper', nav.element).exists('always there')
    await a11yAudit()

    await start.open()
    assert
      .dom(nav.viewport)
      .hasClass('jn-navigation-menu-viewport')
      .hasAttribute('data-slot', 'navigation-menu-viewport')
      .hasAttribute('data-state', 'open')
    assert.strictEqual(
      nav.viewport!.parentElement!.className,
      'jn-navigation-menu-viewport-wrapper',
      'in its wrapper',
    )
    assert
      .dom(start.content)
      .hasClass('jn-navigation-menu-content')
      .hasAttribute('data-slot', 'navigation-menu-content')
    assert.dom(start.link('Introduction')).hasClass('jn-navigation-menu-link')
    await a11yAudit()
  })

  test('its style sheet sizes and places it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 100px; width: 1000px">
          <Demo />
        </div>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    const root = getComputedStyle(nav.element)
    assert.strictEqual(root.display, 'flex')
    assert.strictEqual(root.position, 'relative')
    assert.strictEqual(root.justifyContent, 'center')
    const list = getComputedStyle(nav.list)
    assert.strictEqual(list.display, 'flex')
    assert.strictEqual(list.listStyleType, 'none')

    const start = nav.item('Getting started')
    const trigger = getComputedStyle(start.trigger)
    assert.strictEqual(trigger.display, 'inline-flex')
    assert.strictEqual(trigger.height, '36px', 'h-9')
    assert.strictEqual(trigger.paddingInlineStart, '10px', 'px-2.5')
    assert.strictEqual(trigger.paddingTop, '6px', 'py-1.5')
    assert.strictEqual(trigger.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(px(trigger.fontSize), 14, 'text-sm')
    assert.strictEqual(trigger.fontWeight, '500', 'font-medium')
    const icon = start.trigger.querySelector('svg')!
    assert.strictEqual(getComputedStyle(icon).width, '12px', 'its chevron is size-3')
    assert.strictEqual(getComputedStyle(icon).marginInlineStart, '4px', 'ms-1')

    await start.open()
    const viewport = nav.viewport!
    finishAnimations(nav.element)
    const content = start.content!
    const v = getComputedStyle(viewport)
    assert.strictEqual(v.backgroundColor, token('--popover'), 'bg-popover')
    assert.strictEqual(v.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.notStrictEqual(v.boxShadow, 'none', 'shadow and its ring')
    assert.strictEqual(v.overflow, 'hidden')
    assert.strictEqual(v.marginTop, '6px', 'mt-1.5')
    // The test container is drawn at half size, so these compare layout sizes, not rects.
    assert.strictEqual(viewport.offsetWidth, content.offsetWidth, 'as wide as the content')
    assert.strictEqual(viewport.offsetHeight, content.offsetHeight, 'and as tall')
    assert.strictEqual(content.offsetWidth, 384 + 8, 'the content’s own width, and its p-1')
    const wrapper = viewport.parentElement!
    assert.strictEqual(wrapper.offsetTop, nav.element.offsetHeight, 'below the menu (top-full)')
    assert.strictEqual(viewport.offsetTop, 6, 'mt-1.5')
    assert.strictEqual(getComputedStyle(content).position, 'absolute', 'md:absolute')
    assert.notStrictEqual(
      getComputedStyle(start.trigger).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'the open trigger is tinted (data-open:bg-muted/50)',
    )
    assert.strictEqual(
      getComputedStyle(icon).rotate,
      '180deg',
      'the chevron turns while it is open',
    )
    const link = getComputedStyle(start.link('Introduction'))
    assert.strictEqual(link.paddingTop, '8px', 'p-2')
    assert.strictEqual(link.borderTopLeftRadius, '8px', 'rounded-md, in a content')
    await a11yAudit()

    await nav.item('Components').open()
    finishAnimations(nav.element)
    assert.strictEqual(viewport.offsetWidth, 500 + 8, 'the viewport takes the new content’s width')
    await a11yAudit()
  })

  test('the keyboard: Tab into the open content and on, Escape back to the trigger', async function (assert) {
    await render(<template><Demo /></template>)
    const nav = new NavigationMenuHarness()
    const start = nav.item('Getting started')
    await start.openWithKeyboard()
    assert.true(start.isOpen)
    await tab()
    assert.strictEqual(nav.focused, 'Introduction')
    await pressKey('ArrowDown')
    assert.strictEqual(nav.focused, 'Installation')
    await nav.pressEscape()
    assert.false(start.isOpen)
    assert.dom(start.trigger).isFocused()
    await pressKey('ArrowRight')
    assert.strictEqual(nav.focused, 'Components')
    await a11yAudit()
  })

  test('without a viewport, each content is a panel of its own below its trigger', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 100px; width: 1000px">
          <Demo @viewport={{false}} />
        </div>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    assert.dom(nav.element).hasAttribute('data-viewport', 'false')
    assert.dom('.jn-navigation-menu-viewport-wrapper', nav.element).doesNotExist()
    const start = nav.item('Getting started')
    await start.open()
    const content = start.content!
    finishAnimations(content)
    assert.ok(start.trigger.closest('li')!.contains(content), 'in its item')
    const style = getComputedStyle(content)
    assert.strictEqual(style.backgroundColor, token('--popover'), 'bg-popover')
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style.marginTop, '6px', 'mt-1.5')
    assert.strictEqual(
      content.offsetTop,
      start.trigger.offsetHeight + 6,
      'below its trigger (top-full), 6px off',
    )
    await a11yAudit()
  })

  test('right to left, the viewport starts at the right', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 100px; width: 1000px">
          <DirectionProvider @dir="rtl"><Demo /></DirectionProvider>
        </div>
      </template>,
    )
    const nav = new NavigationMenuHarness()
    await nav.item('Getting started').open()
    finishAnimations(nav.element)
    const wrapper = nav.viewport!.parentElement!
    assert.true(
      Math.abs(rect(wrapper).right - rect(nav.element).right) <= 1,
      'start-0 is the right edge',
    )
    const icon = nav.trigger('Getting started').querySelector('svg')!
    assert.strictEqual(getComputedStyle(icon).marginInlineStart, '4px')
    assert.true(
      rect(icon).left < rect(nav.trigger('Getting started')).left + 20,
      'the chevron after the text, on the left',
    )
    await a11yAudit()
  })
})
