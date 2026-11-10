import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { focus, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Home, Inbox, Plus } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Collapsible,
  DropdownMenu,
  Icon,
  SidebarProvider,
  sidebarStateFromCookie,
} from '@ember-joinery/ember'
import {
  CollapsibleHarness,
  DropdownMenuHarness,
  SidebarHarness,
  SidebarMenuButtonHarness,
  SidebarMenuSubButtonHarness,
  pressKey,
} from '@ember-joinery/test-support'

const px = (element: Element | null, property: keyof CSSStyleDeclaration) =>
  element ? (getComputedStyle(element)[property] as string) : ''

/** Ends any transitions, so the sidebar is measured where it rests. */
function settle(element: Element | null): void {
  for (const animation of element?.getAnimations({ subtree: true }) ?? []) animation.finish()
}

function clearCookie(): void {
  document.cookie = 'sidebar_state=; path=/; max-age=0'
}

class State {
  @tracked open = true
  setOpen = (open: boolean) => (this.open = open)
}

class Breakpoint {
  @tracked width = 768
}

module('Integration | components | sidebar', function (hooks) {
  setupRenderingTest(hooks)
  hooks.afterEach(clearCookie)

  test("it renders upstream's parts, with upstream's classes and data attributes", async function (assert) {
    await render(
      <template>
        <SidebarProvider @name="app" as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Header>Acme</sidebar.Header>
            <sidebar.Content>
              <sidebar.Group>
                <sidebar.GroupLabel>Application</sidebar.GroupLabel>
                <sidebar.GroupAction title="Add Project">
                  <Icon @icon={{Plus}} />
                  <span class="sr-only">Add Project</span>
                </sidebar.GroupAction>
                <sidebar.GroupContent>
                  <sidebar.Menu>
                    <sidebar.MenuItem>
                      <sidebar.MenuButton @isActive={{true}} @name="home">
                        <Icon @icon={{Home}} />
                        <span>Home</span>
                      </sidebar.MenuButton>
                      <sidebar.MenuBadge>24</sidebar.MenuBadge>
                    </sidebar.MenuItem>
                    <sidebar.MenuItem>
                      <sidebar.MenuButton @as="a" href="/inbox">
                        <Icon @icon={{Inbox}} />
                        <span>Inbox</span>
                      </sidebar.MenuButton>
                      <sidebar.MenuSub>
                        <sidebar.MenuSubItem>
                          <sidebar.MenuSubButton href="/unread">Unread</sidebar.MenuSubButton>
                        </sidebar.MenuSubItem>
                      </sidebar.MenuSub>
                    </sidebar.MenuItem>
                  </sidebar.Menu>
                </sidebar.GroupContent>
              </sidebar.Group>
              <sidebar.Separator />
            </sidebar.Content>
            <sidebar.Footer>Footer</sidebar.Footer>
            <sidebar.Rail />
          </sidebar.Sidebar>
          <sidebar.Inset>
            <sidebar.Trigger />
          </sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness('app')
    const wrapper = sidebar.element
    assert
      .dom(wrapper)
      .hasClass('jn-sidebar-wrapper')
      .hasClass('group/sidebar-wrapper')
      .hasAttribute('data-slot', 'sidebar-wrapper')
      .hasAttribute('data-test-jn', 'sidebar')

    const panel = sidebar.panel!
    assert.deepEqual(
      rendering(panel).classes,
      ['group', 'jn-sidebar', 'peer'],
      'the desktop panel keeps the group and peer markers',
    )
    assert
      .dom(panel)
      .hasAttribute('data-slot', 'sidebar')
      .hasAttribute('data-state', 'expanded')
      .hasAttribute('data-collapsible', '')
      .hasAttribute('data-variant', 'sidebar')
      .hasAttribute('data-side', 'left')
    assert.dom('[data-slot="sidebar-gap"]', panel).hasClass('jn-sidebar-gap')
    assert.dom(sidebar.container).hasClass('jn-sidebar-container').hasAttribute('data-side', 'left')
    assert
      .dom('[data-slot="sidebar-inner"]', panel)
      .hasClass('jn-sidebar-inner')
      .hasAttribute('data-sidebar', 'sidebar')

    for (const [slot, sidebarAttr, tag] of [
      ['sidebar-header', 'header', 'DIV'],
      ['sidebar-content', 'content', 'DIV'],
      ['sidebar-group', 'group', 'DIV'],
      ['sidebar-group-label', 'group-label', 'DIV'],
      ['sidebar-group-action', 'group-action', 'BUTTON'],
      ['sidebar-group-content', 'group-content', 'DIV'],
      ['sidebar-menu', 'menu', 'UL'],
      ['sidebar-menu-item', 'menu-item', 'LI'],
      ['sidebar-menu-badge', 'menu-badge', 'DIV'],
      ['sidebar-menu-sub', 'menu-sub', 'UL'],
      ['sidebar-menu-sub-item', 'menu-sub-item', 'LI'],
      ['sidebar-separator', 'separator', 'DIV'],
      ['sidebar-footer', 'footer', 'DIV'],
      ['sidebar-rail', 'rail', 'BUTTON'],
      ['sidebar-inset', undefined, 'MAIN'],
      ['sidebar-trigger', 'trigger', 'BUTTON'],
    ] as const) {
      const element = wrapper.querySelector(`[data-slot="${slot}"]`)
      assert.dom(element).hasClass(`jn-${slot}`, slot).hasTagName(tag.toLowerCase())
      if (sidebarAttr) assert.dom(element).hasAttribute('data-sidebar', sidebarAttr)
    }
    assert.dom('[data-slot="sidebar-menu-item"]', wrapper).hasClass('group/menu-item')
    assert.dom('[data-slot="sidebar-menu-sub-item"]', wrapper).hasClass('group/menu-sub-item')
    assert
      .dom('[data-slot="sidebar-separator"]', wrapper)
      .hasAttribute('role', 'none')
      .hasAttribute('aria-hidden', 'true')
      .hasAttribute('data-orientation', 'horizontal')

    const home = sidebar.menuButton('Home')
    assert.dom(home.element).hasTagName('button').hasAttribute('data-slot', 'sidebar-menu-button')
    assert.deepEqual(rendering(home.element).classes, [
      'group/menu-button',
      'jn-sidebar-menu-button',
      'jn-sidebar-menu-button-size-default',
      'jn-sidebar-menu-button-variant-default',
      'peer/menu-button',
    ])
    assert
      .dom(home.element)
      .hasAttribute('data-sidebar', 'menu-button')
      .hasAttribute('data-size', 'default')
      .hasAttribute('data-active', 'true')
    assert.true(home.isActive)
    assert.strictEqual(home.variant, 'default')
    assert.strictEqual(new SidebarMenuButtonHarness('home').label, 'Home')
    const inbox = sidebar.menuButton('Inbox')
    assert.dom(inbox.element).hasTagName('a').hasAttribute('data-active', 'false')
    assert.strictEqual(inbox.href, '/inbox')
    const unread = sidebar.menuSubButton('Unread')
    assert
      .dom(unread.element)
      .hasTagName('a')
      .hasClass('jn-sidebar-menu-sub-button')
      .hasAttribute('data-slot', 'sidebar-menu-sub-button')
      .hasAttribute('data-sidebar', 'menu-sub-button')
      .hasAttribute('data-size', 'md')
      .hasAttribute('data-active', 'false')

    assert.deepEqual(sidebar.menuButtonLabels, ['Home', 'Inbox'])
    assert.deepEqual(sidebar.menuSubButtonLabels, ['Unread'])
    assert.deepEqual(sidebar.groupLabels, ['Application'])
    assert.deepEqual(sidebar.badges, ['24'])
    assert.strictEqual(sidebar.state, 'expanded')
    assert.true(sidebar.isOpen)
    assert.false(sidebar.isMobile)
    assert.strictEqual(sidebar.variant, 'sidebar')
    assert.strictEqual(sidebar.side, 'left')
    assert.dom(sidebar.inset).hasTagName('main')
    assert
      .dom(sidebar.trigger)
      .hasAttribute('data-test-jn', 'button')
      .hasAttribute('data-variant', 'ghost')
      .hasAttribute('data-size', 'icon-sm')
      .hasAttribute('aria-expanded', 'true')
      .hasText('Toggle Sidebar')
    assert.dom('svg', sidebar.trigger).hasClass('jn-rtl-flip')
    assert
      .dom(sidebar.rail)
      .hasAttribute('aria-label', 'Toggle Sidebar')
      .hasAttribute('title', 'Toggle Sidebar')
      .hasAttribute('tabindex', '-1')
    await a11yAudit()
  })

  test('its style sheet lays it out, without Tailwind', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Header>Acme</sidebar.Header>
            <sidebar.Content>
              <sidebar.Group>
                <sidebar.GroupLabel>Projects</sidebar.GroupLabel>
                <sidebar.Menu>
                  <sidebar.MenuItem>
                    <sidebar.MenuButton @name="default">Default</sidebar.MenuButton>
                  </sidebar.MenuItem>
                  <sidebar.MenuItem>
                    <sidebar.MenuButton @size="sm" @name="sm">Small</sidebar.MenuButton>
                  </sidebar.MenuItem>
                  <sidebar.MenuItem>
                    <sidebar.MenuButton @size="lg" @variant="outline" @name="lg">
                      Large
                    </sidebar.MenuButton>
                  </sidebar.MenuItem>
                </sidebar.Menu>
              </sidebar.Group>
            </sidebar.Content>
          </sidebar.Sidebar>
          <sidebar.Inset>Page</sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    assert.strictEqual(px(sidebar.element, 'display'), 'flex', 'the wrapper is a row')
    assert.strictEqual(px(sidebar.panel, 'display'), 'block', 'md:block, on a wide screen')
    assert.strictEqual(px(sidebar.container, 'position'), 'fixed')
    assert.strictEqual(px(sidebar.container, 'width'), '256px', '--sidebar-width, 16rem')
    assert.strictEqual(px(sidebar.container, 'borderRightWidth'), '1px', 'its inner edge')
    const gap = sidebar.panel!.querySelector('[data-slot="sidebar-gap"]')
    assert.strictEqual(px(gap, 'width'), '256px', 'the gap holds its room on the page')
    const inner = sidebar.panel!.querySelector('[data-slot="sidebar-inner"]')!
    assert.strictEqual(px(inner, 'backgroundColor'), px(inner, 'backgroundColor'))
    assert.notStrictEqual(px(inner, 'backgroundColor'), 'rgba(0, 0, 0, 0)', 'bg-sidebar')
    const header = sidebar.element.querySelector('[data-slot="sidebar-header"]')
    assert.strictEqual(px(header, 'padding'), '8px', 'p-2')
    assert.strictEqual(px(new SidebarMenuButtonHarness('default').element, 'height'), '32px')
    assert.strictEqual(px(new SidebarMenuButtonHarness('sm').element, 'height'), '28px')
    assert.strictEqual(px(new SidebarMenuButtonHarness('lg').element, 'height'), '48px')
    assert.strictEqual(new SidebarMenuButtonHarness('lg').variant, 'outline')
    assert.notStrictEqual(
      px(new SidebarMenuButtonHarness('lg').element, 'boxShadow'),
      'none',
      'the outline variant draws its ring with a shadow',
    )
    const label = sidebar.element.querySelector('[data-slot="sidebar-group-label"]')
    assert.strictEqual(px(label, 'height'), '32px', 'h-8')
    assert.strictEqual(px(label, 'fontSize'), '12px', 'text-xs')
    assert.strictEqual(px(sidebar.inset, 'flexGrow'), '1', 'the page takes the rest')
    await a11yAudit()
  })

  test('the trigger, the rail and the keyboard shortcut open and close it; the state is kept in a cookie', async function (assert) {
    clearCookie()
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar @collapsible="icon">
            <sidebar.Content>Content</sidebar.Content>
            <sidebar.Rail />
          </sidebar.Sidebar>
          <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    assert.strictEqual(sidebarStateFromCookie(), undefined, 'no cookie yet')
    assert.strictEqual(sidebar.collapsible, null, 'data-collapsible is empty while open')

    await sidebar.toggle()
    settle(sidebar.panel)
    assert.strictEqual(sidebar.state, 'collapsed')
    assert.false(sidebar.isOpen)
    assert.dom(sidebar.panel).hasAttribute('data-collapsible', 'icon')
    assert.strictEqual(sidebar.collapsible, 'icon')
    assert.dom(sidebar.trigger).hasAttribute('aria-expanded', 'false')
    assert.strictEqual(px(sidebar.container, 'width'), '48px', '--sidebar-width-icon, 3rem')
    assert.true(document.cookie.includes('sidebar_state=false'), 'the cookie says closed')
    assert.false(sidebarStateFromCookie())

    await sidebar.toggleWithRail()
    assert.true(sidebar.isOpen, 'the rail opens it')
    assert.true(sidebarStateFromCookie())

    await focus(sidebar.trigger)
    assert.true(await sidebar.pressShortcut(), 'Ctrl+B is taken')
    assert.false(sidebar.isOpen, 'Ctrl+B closes it')
    await sidebar.pressShortcut({ metaKey: true })
    assert.true(sidebar.isOpen, '⌘B opens it')
    assert.false(await pressKey('b'), 'b alone is left alone')
    assert.true(sidebar.isOpen)
    await a11yAudit()
  })

  test('offcanvas slides it off the screen', async function (assert) {
    await render(
      <template>
        <SidebarProvider @defaultOpen={{false}} as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Content>Content</sidebar.Content>
          </sidebar.Sidebar>
          <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    settle(sidebar.panel)
    assert.strictEqual(sidebar.state, 'collapsed', '@defaultOpen={{false}} starts it closed')
    assert.strictEqual(sidebar.collapsible, 'offcanvas')
    assert.strictEqual(px(sidebar.container, 'left'), '-256px', 'off the left edge')
    const gap = sidebar.panel!.querySelector('[data-slot="sidebar-gap"]')
    assert.strictEqual(px(gap, 'width'), '0px', 'and gives the page its room back')
    await sidebar.open()
    settle(sidebar.panel)
    assert.strictEqual(px(sidebar.container, 'left'), '0px')
    await a11yAudit()
  })

  test('controlled, it shows @open and tells @onOpenChange', async function (assert) {
    const state = new State()
    const heard: boolean[] = []
    const onOpenChange = (open: boolean) => {
      heard.push(open)
      state.setOpen(open)
    }
    await render(
      <template>
        <SidebarProvider @open={{state.open}} @onOpenChange={{onOpenChange}} as |sidebar|>
          <sidebar.Sidebar><sidebar.Content>Content</sidebar.Content></sidebar.Sidebar>
          <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    await sidebar.toggle()
    assert.deepEqual(heard, [false])
    assert.false(sidebar.isOpen)
    state.setOpen(true)
    await settled()
    assert.true(sidebar.isOpen, 'it follows @open')
    await a11yAudit()
  })

  test('controlled without @onOpenChange, it stays as @open says', async function (assert) {
    await render(
      <template>
        <SidebarProvider @open={{true}} as |sidebar|>
          <sidebar.Sidebar><sidebar.Content>Content</sidebar.Content></sidebar.Sidebar>
          <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    await sidebar.toggle()
    assert.true(sidebar.isOpen)
    await a11yAudit()
  })

  test('@keyboardShortcut changes the key, or turns it off', async function (assert) {
    await render(
      <template>
        <SidebarProvider @name="k" @keyboardShortcut="k" style="min-height: 0" as |sidebar|>
          <sidebar.Sidebar><sidebar.Content>K</sidebar.Content></sidebar.Sidebar>
        </SidebarProvider>
        <SidebarProvider @name="off" @keyboardShortcut={{false}} style="min-height: 0" as |sidebar|>
          <sidebar.Sidebar><sidebar.Content>Off</sidebar.Content></sidebar.Sidebar>
        </SidebarProvider>
      </template>,
    )
    const k = new SidebarHarness('k')
    const off = new SidebarHarness('off')
    await k.pressShortcut()
    assert.true(k.isOpen, 'Ctrl+B is not its shortcut')
    await k.pressShortcut({ key: 'k' })
    assert.false(k.isOpen, 'Ctrl+K is')
    assert.true(off.isOpen, 'no shortcut opens or closes the other')
    await a11yAudit()
  })

  test('@cookieName names the cookie, and false keeps none', async function (assert) {
    clearCookie()
    await render(
      <template>
        <SidebarProvider @name="named" @cookieName="nav_state" style="min-height: 0" as |sidebar|>
          <sidebar.Sidebar><sidebar.Content>Named</sidebar.Content></sidebar.Sidebar>
          <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
        <SidebarProvider
          @name="none"
          @cookieName={{false}}
          @keyboardShortcut={{false}}
          style="min-height: 0"
          as |sidebar|
        >
          <sidebar.Sidebar><sidebar.Content>None</sidebar.Content></sidebar.Sidebar>
          <sidebar.Inset @as="div"><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    await new SidebarHarness('named').toggle()
    assert.false(sidebarStateFromCookie('nav_state'))
    await new SidebarHarness('none').toggle()
    assert.strictEqual(sidebarStateFromCookie(), undefined, 'none written')
    document.cookie = 'nav_state=; path=/; max-age=0'
    await a11yAudit()
  })

  test('the floating and inset variants, and a sidebar on the right', async function (assert) {
    await render(
      <template>
        <SidebarProvider @name="floating" style="min-height: 0" as |sidebar|>
          <sidebar.Sidebar @variant="floating" @collapsible="icon">
            <sidebar.Content>Floating</sidebar.Content>
          </sidebar.Sidebar>
          <sidebar.Inset @as="div"><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
        <SidebarProvider @name="inset" style="min-height: 0" as |sidebar|>
          <sidebar.Sidebar @variant="inset" @side="right">
            <sidebar.Content>Inset</sidebar.Content>
          </sidebar.Sidebar>
          <sidebar.Inset>Page</sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const floating = new SidebarHarness('floating')
    assert.strictEqual(floating.variant, 'floating')
    assert.strictEqual(px(floating.container, 'paddingTop'), '8px', 'p-2 around the panel')
    assert.strictEqual(px(floating.container, 'borderRightWidth'), '0px', 'no border')
    const inner = floating.panel!.querySelector('[data-slot="sidebar-inner"]')
    assert.notStrictEqual(px(inner, 'boxShadow'), 'none', 'a floating panel has a ring and shadow')
    await floating.toggle()
    settle(floating.panel)
    assert.strictEqual(
      px(floating.container, 'width'),
      '66px',
      'icon width, plus room: 3rem + 1rem + 2px',
    )

    const inset = new SidebarHarness('inset')
    assert.strictEqual(inset.side, 'right')
    assert.strictEqual(px(inset.container, 'right'), '0px', 'against the right edge')
    assert.strictEqual(px(inset.inset, 'marginTop'), '8px', 'md:peer-data-[variant=inset]:m-2')
    assert.strictEqual(
      px(inset.inset, 'borderTopLeftRadius'),
      px(inset.inset, 'borderTopRightRadius'),
    )
    assert.notStrictEqual(
      px(inset.element, 'backgroundColor'),
      'rgba(0, 0, 0, 0)',
      'the wrapper takes the sidebar colour around an inset page',
    )
    await a11yAudit()
  })

  test('collapsible="none" is a plain panel', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar @collapsible="none" class="h-auto">
            <sidebar.Content>Always here</sidebar.Content>
          </sidebar.Sidebar>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    assert.dom(sidebar.panel).hasClass('jn-sidebar-static').hasClass('h-auto')
    assert
      .dom(sidebar.panel)
      .hasAttribute('data-slot', 'sidebar')
      .doesNotHaveAttribute('data-state')
    assert.strictEqual(sidebar.collapsible, 'none')
    assert.strictEqual(sidebar.state, null)
    assert.strictEqual(px(sidebar.panel, 'width'), '256px')
    assert.strictEqual(px(sidebar.panel, 'display'), 'flex')
    await a11yAudit()
  })

  test('below the mobile breakpoint it is a sheet, with its own open state', async function (assert) {
    await render(
      <template>
        <SidebarProvider @mobileBreakpoint={{100000}} as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Content>
              <sidebar.Menu>
                <sidebar.MenuItem>
                  <sidebar.MenuButton @tooltip="Home">Home</sidebar.MenuButton>
                </sidebar.MenuItem>
              </sidebar.Menu>
            </sidebar.Content>
          </sidebar.Sidebar>
          <sidebar.Inset>
            <sidebar.Trigger />
            <p>{{if sidebar.isMobile "mobile" "desktop"}}</p>
          </sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    assert.true(sidebar.isMobile)
    assert.dom(sidebar.inset!.querySelector('p')).hasText('mobile', 'it yields isMobile')
    assert.false(sidebar.isOpen, 'the sheet starts closed, whatever the desktop state')
    assert.strictEqual(sidebar.panel, null)
    assert.dom(sidebar.trigger).hasAttribute('aria-expanded', 'false')

    await sidebar.toggle()
    assert.true(sidebar.isOpen)
    assert.strictEqual(sidebar.state, 'expanded')
    assert.dom(sidebar.trigger).hasAttribute('aria-expanded', 'true')
    const panel = sidebar.panel!
    assert
      .dom(panel)
      .hasClass('jn-sheet-content')
      .hasClass('jn-sidebar-mobile')
      .hasAttribute('data-sidebar', 'sidebar')
      .hasAttribute('data-mobile', 'true')
      .hasAttribute('role', 'dialog')
    assert.strictEqual(sidebar.sheet.label, 'Sidebar', 'named for screen readers')
    assert.strictEqual(sidebar.sheet.description?.textContent, 'Displays the mobile sidebar.')
    assert.strictEqual(sidebar.sheet.closeButton, null, 'no close button, as upstream hides it')
    assert.strictEqual(sidebar.side, 'left')
    assert.strictEqual(px(panel, 'paddingTop'), '0px', 'p-0')
    assert.strictEqual(
      px(panel.querySelector('.jn-sidebar-mobile-inner'), 'display'),
      'flex',
      'its content in a column',
    )
    assert.deepEqual(sidebar.menuButtonLabels, ['Home'], 'the menu is in the sheet')
    assert.strictEqual(
      sidebar.elements('menu').length,
      1,
      'and the sheet’s parts are the sidebar’s',
    )
    const home = sidebar.menuButton('Home')
    await home.hover()
    assert.false(home.isTooltipShown, 'no tooltips on mobile')
    await a11yAudit()

    await sidebar.close()
    assert.false(sidebar.isOpen, 'Escape closes it')
    assert.dom(sidebar.trigger).isFocused('focus goes back to the trigger')

    await sidebar.pressShortcut()
    assert.true(sidebar.isOpen, 'the shortcut opens the sheet')
    await sidebar.pressOutside()
    assert.false(sidebar.isOpen, 'a press outside closes it')
    await a11yAudit()
  })

  test('it follows @mobileBreakpoint as it changes', async function (assert) {
    const breakpoint = new Breakpoint()
    await render(
      <template>
        <SidebarProvider @mobileBreakpoint={{breakpoint.width}} as |sidebar|>
          <sidebar.Sidebar><sidebar.Content>Content</sidebar.Content></sidebar.Sidebar>
          <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    assert.false(sidebar.isMobile, `a ${window.innerWidth}px window is wider than 768px`)
    breakpoint.width = window.innerWidth + 1
    await settled()
    assert.true(sidebar.isMobile, 'one pixel narrower than the breakpoint, it is a sheet')
    breakpoint.width = window.innerWidth
    await settled()
    assert.false(sidebar.isMobile, 'as wide as the breakpoint, it is not')
    assert.true(sidebar.isOpen, 'and the desktop sidebar kept its state')
    await a11yAudit()
  })

  test('a menu button with a tooltip shows it only while the sidebar is collapsed', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar @collapsible="icon">
            <sidebar.Content>
              <sidebar.Menu>
                <sidebar.MenuItem>
                  <sidebar.MenuButton @tooltip="Inbox">
                    <Icon @icon={{Inbox}} />
                    <span>Inbox</span>
                  </sidebar.MenuButton>
                </sidebar.MenuItem>
              </sidebar.Menu>
            </sidebar.Content>
          </sidebar.Sidebar>
          <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    const inbox = sidebar.menuButton('Inbox')
    await inbox.hover()
    assert.false(inbox.isTooltipShown, 'expanded: the label is there already')
    assert.strictEqual(inbox.tooltip, '', 'so it says nothing more')
    await inbox.unhover()

    await sidebar.toggle()
    settle(sidebar.panel)
    assert.strictEqual(px(inbox.element, 'width'), '32px', 'collapsed to its icon: size-8')
    await inbox.hover()
    assert.true(inbox.isTooltipShown)
    assert.strictEqual(inbox.tooltip, 'Inbox')
    assert.strictEqual(inbox.tooltipElement?.getAttribute('data-side'), 'right')
    await a11yAudit()
    await inbox.unhover()
    assert.strictEqual(inbox.tooltip, '')
  })

  test('menu actions, with @showOnHover', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Content>
              <sidebar.Menu>
                <sidebar.MenuItem>
                  <sidebar.MenuButton>Projects</sidebar.MenuButton>
                  <sidebar.MenuAction data-case="always">
                    <Icon @icon={{Plus}} />
                    <span class="sr-only">Add</span>
                  </sidebar.MenuAction>
                </sidebar.MenuItem>
                <sidebar.MenuItem>
                  <sidebar.MenuButton>Archive</sidebar.MenuButton>
                  <sidebar.MenuAction @showOnHover={{true}} data-case="hover" aria-label="More" />
                </sidebar.MenuItem>
              </sidebar.Menu>
            </sidebar.Content>
          </sidebar.Sidebar>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    const [always, hover] = sidebar.elements('menu-action')
    assert
      .dom(always)
      .hasClass('jn-sidebar-menu-action')
      .hasAttribute('data-slot', 'sidebar-menu-action')
      .hasAttribute('data-sidebar', 'menu-action')
      .doesNotHaveAttribute('data-show-on-hover')
    assert.dom(hover).hasAttribute('data-show-on-hover', 'true')
    assert.strictEqual(px(always!, 'opacity'), '1')
    assert.strictEqual(px(hover!, 'opacity'), '0', 'md:opacity-0 until its item is hovered')
    assert.strictEqual(px(always!, 'position'), 'absolute')
    const projects = sidebar.menuButton('Projects')
    assert.strictEqual(
      px(projects.element, 'paddingRight'),
      '32px',
      'the button leaves room for its action (pe-8)',
    )
    await focus(hover!)
    assert.strictEqual(px(hover!, 'opacity'), '1', 'focus within the item shows it')
    await a11yAudit()
  })

  test('menu buttons and actions are other components’ triggers', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Content>
              <sidebar.Menu>
                <Collapsible
                  @as="li"
                  @name="docs"
                  class="group/collapsible"
                  {{sidebar.menuItem}}
                  as |c|
                >
                  <sidebar.MenuButton {{c.trigger}}>Docs</sidebar.MenuButton>
                  <c.Content>
                    <sidebar.MenuSub>
                      <sidebar.MenuSubItem>
                        <sidebar.MenuSubButton href="/intro">Intro</sidebar.MenuSubButton>
                      </sidebar.MenuSubItem>
                    </sidebar.MenuSub>
                  </c.Content>
                </Collapsible>
                <sidebar.MenuItem>
                  <sidebar.MenuButton>Projects</sidebar.MenuButton>
                  <DropdownMenu @name="project" as |m|>
                    <sidebar.MenuAction {{m.trigger}}>
                      <span class="sr-only">More</span>
                    </sidebar.MenuAction>
                    <m.Content>
                      <m.Item>Edit Project</m.Item>
                    </m.Content>
                  </DropdownMenu>
                </sidebar.MenuItem>
              </sidebar.Menu>
            </sidebar.Content>
          </sidebar.Sidebar>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    const docs = new CollapsibleHarness('docs')
    assert.dom(docs.element).hasTagName('li').hasClass('jn-sidebar-menu-item')
    assert.dom(docs.element).hasAttribute('data-slot', 'sidebar-menu-item')
    assert.strictEqual(
      sidebar.elements('menu-item').length,
      2,
      'the collapsible is still a menu item',
    )
    const button = sidebar.menuButton('Docs')
    assert.strictEqual(docs.trigger, button.element, 'the menu button is its trigger')
    assert.false(button.isExpanded)
    assert.deepEqual(sidebar.menuSubButtonLabels, [], 'closed, its submenu is hidden')
    await button.click()
    assert.true(docs.isOpen)
    assert.true(button.isExpanded)
    assert.deepEqual(sidebar.menuSubButtonLabels, ['Intro'])
    assert.strictEqual(sidebar.elements('menu-sub').length, 1, 'the submenu stays the sidebar’s')

    const project = sidebar.find(DropdownMenuHarness, 'project')
    assert.dom(project.trigger).hasClass('jn-sidebar-menu-action')
    await project.open()
    assert.deepEqual(project.items, ['Edit Project'])
    await a11yAudit()
  })

  test('the modifiers make your own elements the parts', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar>
            <div {{sidebar.content}}>
              <ul {{sidebar.menu}}>
                <li {{sidebar.menuItem}}>
                  <a
                    href="/a"
                    data-case="modifier"
                    {{sidebar.menuButton isActive=true size="lg"}}
                  >A</a>
                  <sidebar.MenuButton
                    @as="a"
                    @isActive={{true}}
                    @size="lg"
                    href="/a"
                    data-case="component"
                  >A</sidebar.MenuButton>
                </li>
                <li {{sidebar.menuSubItem}}>
                  <a href="/b" data-case="modifier" {{sidebar.menuSubButton size="sm"}}>B</a>
                  <sidebar.MenuSubButton
                    @size="sm"
                    href="/b"
                    data-case="component"
                  >B</sidebar.MenuSubButton>
                </li>
              </ul>
            </div>
          </sidebar.Sidebar>
          <button type="button" {{sidebar.trigger}}>Menu</button>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    for (const kind of [SidebarMenuButtonHarness, SidebarMenuSubButtonHarness]) {
      const [modifier, component] = sidebar.findAll(kind)
      assert.deepEqual(
        rendering(modifier!.element),
        rendering(component!.element),
        `${kind.component}: the modifier renders what the component does`,
      )
    }
    assert.dom('[data-slot="sidebar-content"]').hasClass('jn-sidebar-content')
    assert.dom(sidebar.trigger).hasText('Menu').hasAttribute('aria-expanded', 'true')
    await sidebar.toggle()
    assert.false(sidebar.isOpen, 'your own trigger closes it')
    assert.dom(sidebar.trigger).hasAttribute('aria-expanded', 'false')
    await a11yAudit()
  })

  test('a menu skeleton is 50 to 90% wide', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Menu>
              <sidebar.MenuItem><sidebar.MenuSkeleton @showIcon={{true}} /></sidebar.MenuItem>
              <sidebar.MenuItem><sidebar.MenuSkeleton /></sidebar.MenuItem>
            </sidebar.Menu>
          </sidebar.Sidebar>
        </SidebarProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    const [withIcon, plain] = sidebar.elements('menu-skeleton') as [HTMLElement, HTMLElement]
    assert.dom(withIcon).hasClass('jn-sidebar-menu-skeleton')
    assert.dom('[data-sidebar="menu-skeleton-icon"]', withIcon).hasClass('jn-skeleton')
    assert.dom('[data-sidebar="menu-skeleton-icon"]', plain).doesNotExist()
    const text = plain.querySelector<HTMLElement>('[data-sidebar="menu-skeleton-text"]')!
    const width = Number.parseFloat(text.style.getPropertyValue('--skeleton-width'))
    assert.true(width >= 50 && width < 90, `${width}%`)
    assert.strictEqual(px(text, 'height'), '16px', 'h-4')
    assert.strictEqual(px(withIcon, 'height'), '32px', 'h-8')
    await a11yAudit()
  })

  test('the input is an Input sized for the sidebar', async function (assert) {
    await render(
      <template>
        <SidebarProvider as |sidebar|>
          <sidebar.Sidebar>
            <sidebar.Header>
              <sidebar.Input @name="search" aria-label="Search" placeholder="Search" />
            </sidebar.Header>
          </sidebar.Sidebar>
        </SidebarProvider>
      </template>,
    )
    const input = document.querySelector('[data-slot="sidebar-input"]')!
    assert
      .dom(input)
      .hasClass('jn-input')
      .hasClass('jn-sidebar-input')
      .hasAttribute('data-test-jn', 'input')
      .hasAttribute('data-sidebar', 'input')
    assert.strictEqual(px(input, 'height'), '32px', 'h-8')
    await a11yAudit()
  })

  test('right to left, logical sides flip', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <SidebarProvider as |sidebar|>
            <sidebar.Sidebar @side="right">
              <sidebar.Content>
                <sidebar.Group>
                  <sidebar.GroupLabel>المشاريع</sidebar.GroupLabel>
                  <sidebar.GroupAction aria-label="إضافة" />
                  <sidebar.Menu>
                    <sidebar.MenuItem>
                      <sidebar.MenuButton>الرئيسية</sidebar.MenuButton>
                      <sidebar.MenuSub>
                        <sidebar.MenuSubItem>
                          <sidebar.MenuSubButton href="#">فرعي</sidebar.MenuSubButton>
                        </sidebar.MenuSubItem>
                      </sidebar.MenuSub>
                    </sidebar.MenuItem>
                  </sidebar.Menu>
                </sidebar.Group>
              </sidebar.Content>
            </sidebar.Sidebar>
            <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
          </SidebarProvider>
        </DirectionProvider>
      </template>,
    )
    const sidebar = new SidebarHarness()
    assert.strictEqual(px(sidebar.container, 'right'), '0px', '@side stays physical')
    const action = sidebar.element.querySelector('[data-slot="sidebar-group-action"]')!
    assert.strictEqual(px(action, 'left'), '12px', 'the group action sits at the inline end: end-3')
    const sub = sidebar.element.querySelector('[data-slot="sidebar-menu-sub"]')!
    assert.strictEqual(
      px(sub, 'borderRightWidth'),
      '1px',
      'the submenu’s line is on its start side',
    )
    assert.strictEqual(px(sub, 'borderLeftWidth'), '0px')
    assert.strictEqual(
      px(sidebar.menuButton('الرئيسية').element, 'textAlign'),
      'start',
      'menu buttons start their text at the start',
    )
    assert.strictEqual(
      px(sidebar.trigger.querySelector('svg'), 'rotate'),
      '180deg',
      'the trigger’s icon mirrors',
    )
    await a11yAudit()
  })
})
