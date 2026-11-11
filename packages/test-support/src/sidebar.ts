import { blur, click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey } from './focus.ts'
import { pressEscape } from './layers.ts'
import { hover, unhover, type HoverOptions } from './pointer.ts'
import { SheetHarness } from './sheet.ts'
import { accessibleDescription, accessibleName, text } from './-private/overlay.ts'
import { findWithin, logicalParent } from './-private/tree.ts'

/**
 * Drives a menu's button or link in a `<SidebarProvider>` (`sidebar.MenuButton`, or your own
 * element with `{{sidebar.menuButton}}`). It is a component root of its own, so it can be a
 * Collapsible's or a Dropdown Menu's trigger too.
 *
 *   const inbox = new SidebarMenuButtonHarness('inbox') // <sidebar.MenuButton @name="inbox">
 *   await inbox.click()
 *   assert.true(inbox.isActive)
 */
export class SidebarMenuButtonHarness extends Harness {
  static override component: string | readonly string[] = 'sidebar-menu-button'

  /** Its accessible name: `aria-label`, `aria-labelledby`'s text, or its own text. */
  get label(): string {
    return accessibleName(this.element)
  }

  /** The text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Whether it is highlighted as the current page's (`@isActive`, its `data-active`). */
  get isActive(): boolean {
    return this.element.getAttribute('data-active') === 'true'
  }

  /** Its `@size`: `default`, `sm` or `lg` (a submenu's: `sm` or `md`). */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** Its `@variant`, `default` or `outline`, from its class (upstream renders no attribute). */
  get variant(): string | null {
    const match = /jn-sidebar-menu-button-variant-(\w+)/.exec(this.element.className)
    return match?.[1] ?? null
  }

  /** Its `href`, for a link. */
  get href(): string | null {
    return this.element.getAttribute('href')
  }

  /**
   * For one that opens something (a Collapsible's or a Dropdown Menu's trigger), whether that
   * is open (`aria-expanded`); otherwise `undefined`.
   */
  get isExpanded(): boolean | undefined {
    const expanded = this.element.getAttribute('aria-expanded')
    return expanded === null ? undefined : expanded === 'true'
  }

  /** Whether it can't be used: `disabled`, or `aria-disabled="true"`. */
  get isDisabled(): boolean {
    const element = this.element
    if ('disabled' in element && (element as HTMLButtonElement).disabled) return true
    return element.getAttribute('aria-disabled') === 'true'
  }

  /**
   * Its tooltip (`@tooltip`) while it is open, as a screen reader hears it: the text its
   * `aria-describedby` names. `''` while closed.
   */
  get tooltip(): string {
    return accessibleDescription(this.element)
  }

  /** The tooltip's element while it is open, or `null`. */
  get tooltipElement(): HTMLElement | null {
    const id = this.element.getAttribute('aria-describedby')
    return id ? this.element.ownerDocument.getElementById(id) : null
  }

  /** Whether its tooltip shows: open, and not `hidden` (it hides while the sidebar is expanded). */
  get isTooltipShown(): boolean {
    const tooltip = this.tooltipElement
    return Boolean(tooltip && !tooltip.hidden && tooltip.matches(':popover-open'))
  }

  /** Whether it has focus. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.element
  }

  async click(): Promise<void> {
    await click(this.element)
  }

  async focus(): Promise<void> {
    await focus(this.element)
  }

  async blur(): Promise<void> {
    await blur(this.element)
  }

  /** Rests the pointer on it, as a mouse does, and waits out its tooltip's delay. */
  async hover(options?: HoverOptions): Promise<void> {
    await hover(this.element, options)
  }

  /** Moves the pointer off it. */
  async unhover(options?: HoverOptions): Promise<void> {
    await unhover(this.element, { ...options, away: this.tooltipElement })
  }
}

/**
 * Drives a submenu's link in a `<SidebarProvider>` (`sidebar.MenuSubButton`, or your own
 * element with `{{sidebar.menuSubButton}}`): a `SidebarMenuButtonHarness` for
 * `data-test-jn="sidebar-menu-sub-button"`.
 */
export class SidebarMenuSubButtonHarness extends SidebarMenuButtonHarness {
  static override component = 'sidebar-menu-sub-button'
}

/** The sidebar an element is in: its nearest `data-test-jn="sidebar"` ancestor in the component tree. */
function sidebarOf(element: Element): Element | null {
  for (let node = logicalParent(element); node; node = logicalParent(node)) {
    if (node.getAttribute('data-test-jn') === 'sidebar') return node
  }
  return null
}

/**
 * Drives a `<SidebarProvider>` from `@ember-joinery/ember` and the sidebar in it. It reads
 * whether the sidebar is open through ARIA, from its trigger's `aria-expanded` (without a
 * trigger, from the panel's `data-state`, or on mobile the sheet's), and acts as a user does:
 * the trigger, the rail, ⌘B (Ctrl+B), and on mobile, Escape or a press outside the sheet.
 *
 *   const sidebar = new SidebarHarness('app') // <SidebarProvider @name="app">
 *   await sidebar.toggle()
 *   assert.strictEqual(sidebar.state, 'collapsed')
 *   await sidebar.pressShortcut()
 *   assert.true(sidebar.isOpen)
 *   assert.deepEqual(sidebar.menuButtonLabels, ['Home', 'Inbox'])
 */
export class SidebarHarness extends Harness {
  static override component = 'sidebar'

  /**
   * The sidebar's panel (`data-slot="sidebar"`): the desktop panel, the plain one with
   * `@collapsible="none"`, or, on mobile, the sheet's content while it is open. `null` when
   * the mobile sheet is closed.
   */
  get panel(): HTMLElement | null {
    return this.queryPart('sidebar') ?? (this.isMobile ? this.sheet.content : null)
  }

  /** The panel inside the desktop sidebar, which your attributes go on (`sidebar-container`). */
  get container(): HTMLElement | null {
    return (
      this.panel?.querySelector<HTMLElement>(':scope > [data-slot="sidebar-container"]') ?? null
    )
  }

  /** The mobile sheet, for a sidebar below its mobile breakpoint. */
  get sheet(): SheetHarness {
    return this.child(SheetHarness)
  }

  /** Whether the viewport is narrower than the mobile breakpoint, so the sidebar is a sheet. */
  get isMobile(): boolean {
    return !this.queryPart('sidebar') && this.sheet.exists
  }

  /**
   * `expanded` or `collapsed`: the desktop panel's `data-state`. On mobile, `expanded` while the
   * sheet is open. `null` for a sidebar that doesn't collapse.
   */
  get state(): 'expanded' | 'collapsed' | null {
    if (this.isMobile)
      return this.sheet.content?.getAttribute('data-state') === 'open' ? 'expanded' : 'collapsed'
    const state = this.queryPart('sidebar')?.getAttribute('data-state')
    return state === 'expanded' || state === 'collapsed' ? state : null
  }

  /**
   * Whether it is open: the desktop panel expanded, or the mobile sheet open. A screen reader
   * hears it from the trigger's `aria-expanded`, so that is what it reads; with no trigger, the
   * panel's `data-state` (on mobile, the sheet's).
   */
  get isOpen(): boolean {
    const expanded = this.queryPart('trigger')?.getAttribute('aria-expanded')
    if (expanded === 'true' || expanded === 'false') return expanded === 'true'
    if (this.isMobile) return this.sheet.content?.getAttribute('data-state') === 'open'
    return this.queryPart('sidebar')?.getAttribute('data-state') === 'expanded'
  }

  /**
   * How it collapsed, while it is collapsed: `offcanvas` or `icon` (the panel's
   * `data-collapsible`, which upstream leaves empty while it is expanded). `none` for one that
   * doesn't collapse; `null` while expanded, and on mobile.
   */
  get collapsible(): string | null {
    const panel = this.queryPart('sidebar')
    if (!panel) return null
    if (!panel.hasAttribute('data-state')) return 'none'
    return panel.getAttribute('data-collapsible') || null
  }

  /** `sidebar`, `floating` or `inset` (`@variant`), on the desktop panel. */
  get variant(): string | null {
    return this.queryPart('sidebar')?.getAttribute('data-variant') ?? null
  }

  /** `left` or `right` (`@side`): the desktop panel's `data-side`, or the sheet's on mobile. */
  get side(): string | null {
    const panel = this.queryPart('sidebar')
    if (panel) return panel.getAttribute('data-side')
    return this.isMobile ? this.sheet.side : null
  }

  /** The trigger: `sidebar.Trigger`, or your own element with `{{sidebar.trigger}}`. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The rail along the sidebar's edge, or `null`. */
  get rail(): HTMLElement | null {
    return this.queryPart('rail')
  }

  /** The page beside the sidebar (`sidebar.Inset`), or `null`. */
  get inset(): HTMLElement | null {
    return this.queryPart('inset')
  }

  /**
   * The sidebar's elements of one kind, by upstream's `data-sidebar` (`group`, `group-label`,
   * `menu`, `menu-item`, `menu-sub`, `menu-badge`…), in document order. Unlike `parts()`, it
   * looks through any component between, such as a Collapsible around a group or the mobile
   * Sheet, whose own parts a sidebar's often are; not into a sidebar inside this one.
   */
  elements(name: string): HTMLElement[] {
    const root = this.element
    return findWithin(root, `[data-sidebar="${CSS.escape(name)}"]`).filter(
      element => sidebarOf(element) === root,
    ) as HTMLElement[]
  }

  /** The text of each group's label, in order. */
  get groupLabels(): string[] {
    return this.elements('group-label').map(element => text(element))
  }

  /** Every menu button in the sidebar (not the submenus'), in order. */
  get menuButtons(): SidebarMenuButtonHarness[] {
    return this.findAll(SidebarMenuButtonHarness)
  }

  /** Every submenu button in the sidebar, in order: those in closed collapsibles aren't there. */
  get menuSubButtons(): SidebarMenuSubButtonHarness[] {
    return this.findAll(SidebarMenuSubButtonHarness)
  }

  /** Each menu button's label, in order. */
  get menuButtonLabels(): string[] {
    return this.menuButtons.map(button => button.label)
  }

  /** Each submenu button's label, in order. */
  get menuSubButtonLabels(): string[] {
    return this.menuSubButtons.map(button => button.label)
  }

  /** The menu button labelled `label`. Throws when there is none. */
  menuButton(label: string): SidebarMenuButtonHarness {
    const found = this.menuButtons.find(button => button.label === label)
    if (!found) {
      throw new Error(
        `Joinery harness: no menu button "${label}" in ${this} (there are ${JSON.stringify(this.menuButtonLabels)})`,
      )
    }
    return found
  }

  /** The submenu button labelled `label`. Throws when there is none. */
  menuSubButton(label: string): SidebarMenuSubButtonHarness {
    const found = this.menuSubButtons.find(button => button.label === label)
    if (!found) {
      throw new Error(
        `Joinery harness: no submenu button "${label}" in ${this} (there are ${JSON.stringify(this.menuSubButtonLabels)})`,
      )
    }
    return found
  }

  /** The text of each menu badge, in order. */
  get badges(): string[] {
    return this.elements('menu-badge').map(element => text(element))
  }

  /** Clicks the trigger, as a user does: it opens or closes the sidebar (the sheet, on mobile). */
  async toggle(): Promise<void> {
    await click(this.trigger)
  }

  /** Opens it with the trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }

  /** Closes it with the trigger (on mobile, Escape), unless it is closed. */
  async close(): Promise<void> {
    if (!this.isOpen) return
    if (this.isMobile) await pressEscape()
    else await this.toggle()
  }

  /** Clicks the rail. */
  async toggleWithRail(): Promise<void> {
    const rail = this.rail
    if (!rail) throw new Error(`Joinery harness: ${this} has no rail`)
    await click(rail)
  }

  /**
   * Presses the keyboard shortcut, ⌘ (`metaKey`) or Ctrl (`ctrlKey`) with `key` (default
   * `b`), on the focused element.
   */
  async pressShortcut({
    key = 'b',
    metaKey = false,
  }: { key?: string; metaKey?: boolean } = {}): Promise<boolean> {
    return pressKey(key, metaKey ? { metaKey: true } : { ctrlKey: true })
  }

  /** On mobile, presses outside the open sheet (on its overlay), which closes it. */
  async pressOutside(): Promise<void> {
    await this.sheet.pressOutside()
  }

  /** Moves focus to the trigger. */
  async focusTrigger(): Promise<void> {
    await focus(this.trigger)
  }
}
