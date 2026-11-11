/* global HTMLElementTagNameMap -- a DOM type, which ESLint's browser globals don't list */
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { get, hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import type Owner from '@ember/owner'
import { registerDestructor } from '@ember/destroyable'
import type { WithBoundArgs } from '@glint/template'
import { PanelLeft } from 'lucide'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { controllable } from '@ember-joinery/primitives/controllable-state'
import { Consume, Provide } from '@ember-joinery/primitives/dom-context'
import { idFor } from '@ember-joinery/primitives/id'
import type { NativeValueArgs } from '@ember-joinery/primitives/native-value'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { separatorAria, type SeparatorOrientation } from '@ember-joinery/primitives/separator'
import { visuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Button from './button.gts'
import Icon, { type IconNode } from './icon.gts'
import Input from './input.gts'
import Sheet from './sheet.gts'
import Skeleton from './skeleton.gts'
import Tooltip from './tooltip.gts'
import { t } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

/** Upstream's `SIDEBAR_COOKIE_NAME`: the cookie the sidebar keeps its open state in. */
export const SIDEBAR_COOKIE_NAME = 'sidebar_state'
/** Upstream's `SIDEBAR_COOKIE_MAX_AGE`: a week, in seconds. */
export const SIDEBAR_COOKIE_MAX_AGE = 60 * 60 * 24 * 7
/** Upstream's `SIDEBAR_KEYBOARD_SHORTCUT`: with ⌘ (or Ctrl), `b` opens and closes the sidebar. */
export const SIDEBAR_KEYBOARD_SHORTCUT = 'b'
/** Upstream's `MOBILE_BREAKPOINT` (`use-mobile`): narrower than this, the sidebar is a sheet. */
export const SIDEBAR_MOBILE_BREAKPOINT = 768

/** Whether the sidebar is open (`expanded`) or closed (`collapsed`), as its `data-state`. */
export type SidebarState = 'expanded' | 'collapsed'

/** The side of the screen the sidebar is on. */
export type SidebarSide = 'left' | 'right'

/** How the sidebar looks: against the page, floating on it, or with the page inset beside it. */
export type SidebarVariant = 'sidebar' | 'floating' | 'inset'

/** How the sidebar closes: off the screen, down to its icons, or not at all. */
export type SidebarCollapsible = 'offcanvas' | 'icon' | 'none'

/** How a menu button looks. */
export type SidebarMenuButtonVariant = 'default' | 'outline'

/** How tall a menu button is. */
export type SidebarMenuButtonSize = 'default' | 'sm' | 'lg'

/** How big a submenu button's text is. */
export type SidebarMenuSubButtonSize = 'sm' | 'md'

/**
 * The sidebar's open state as the cookie holds it, which the provider writes each time the
 * sidebar opens or closes (as upstream's does): `true`, `false`, or `undefined` before it has
 * been set. Give it to `@defaultOpen` to open the sidebar as the user left it:
 *
 *   <SidebarProvider @defaultOpen={{(sidebarStateFromCookie)}} as |sidebar|>
 *
 * Upstream reads the same cookie on the server (Next's `cookies()`); an Ember app reads it here.
 */
export function sidebarStateFromCookie(
  cookieName: string = SIDEBAR_COOKIE_NAME,
  doc: Document | undefined = typeof document === 'undefined' ? undefined : document,
): boolean | undefined {
  const prefix = `${cookieName}=`
  const entry = doc?.cookie
    .split(';')
    .map(cookie => cookie.trim())
    .find(cookie => cookie.startsWith(prefix))
  if (entry === undefined) return undefined
  const value = entry.slice(prefix.length)
  return value === 'true' ? true : value === 'false' ? false : undefined
}

// ----- The parts with nothing of their own to track ------------------------------------------

/**
 * A part's markup: its tag, its classes (upstream's semantic class, renamed `jn-`, and the
 * markers other rules look for, such as `group/menu-item`), upstream's `data-slot` and
 * `data-sidebar` (where upstream gives one), and its `data-test-jn-part`.
 *
 * Only a part that holds nothing of the caller's (a badge, the rail, the trigger) names the
 * provider as its owner (`data-test-jn-owner`), which keeps it the sidebar's inside another
 * component, such as the mobile Sheet. A part that holds the caller's content (a group, a menu,
 * an item) doesn't: a Collapsible around a group, whose trigger is inside the group, would lose
 * its trigger to the sidebar. `SidebarHarness` finds those by upstream's `data-sidebar`, through
 * any component between. A part that is often another component's trigger (a group label, an
 * action) doesn't either, so that component's harness finds it.
 */
interface PartSpec {
  readonly tag: keyof HTMLElementTagNameMap
  readonly class: string
  readonly slot: string
  readonly sidebar: string | undefined
  readonly part: string
  readonly owned: boolean
}

const spec = (
  tag: keyof HTMLElementTagNameMap,
  name: string,
  options: { class?: string; owned?: boolean; sidebar?: false } = {},
): PartSpec => ({
  tag,
  class: options.class ?? `jn-sidebar-${name}`,
  slot: `sidebar-${name}`,
  sidebar: options.sidebar === false ? undefined : name,
  part: name,
  owned: options.owned ?? false,
})

const HEADER = spec('div', 'header')
const FOOTER = spec('div', 'footer')
const CONTENT = spec('div', 'content')
const GROUP = spec('div', 'group')
const GROUP_LABEL = spec('div', 'group-label')
const GROUP_ACTION = spec('button', 'group-action')
const GROUP_CONTENT = spec('div', 'group-content')
const MENU = spec('ul', 'menu')
const MENU_ITEM = spec('li', 'menu-item', { class: 'jn-sidebar-menu-item group/menu-item' })
const MENU_BADGE = spec('div', 'menu-badge', { owned: true })
const MENU_SUB = spec('ul', 'menu-sub')
const MENU_SUB_ITEM = spec('li', 'menu-sub-item', {
  class: 'jn-sidebar-menu-sub-item group/menu-sub-item',
})
// Upstream's SidebarInset has a `data-slot` and no `data-sidebar`.
const INSET = spec('main', 'inset', { sidebar: false })

/**
 * Upstream's `cn-sidebar-trigger`, renamed. No sheet styles it; sidebar.css keeps an open
 * sidebar's ghost trigger from taking the ghost Button's `aria-expanded` look.
 */
const TRIGGER_CLASS = 'jn-sidebar-trigger'

/** A part's attributes, as its component renders them and its modifier sets them. */
function partAttributes(part: PartSpec, owner: string): Record<string, string | undefined> {
  return {
    'data-slot': part.slot,
    'data-sidebar': part.sidebar,
    'data-test-jn-part': part.part,
    'data-test-jn-owner': part.owned ? owner : undefined,
  }
}

const attributeOf = (
  part: PartSpec,
  owner: string,
  name: 'data-slot' | 'data-sidebar' | 'data-test-jn-part' | 'data-test-jn-owner',
): string | undefined => partAttributes(part, owner)[name]

export interface SidebarPartSignature {
  Args: {
    /**
     * The tag to render instead of the part's own, as upstream's `asChild` does for its label
     * and actions (`<s.GroupLabel @as="button" {{c.trigger}}>`). For a component of your own,
     * such as `LinkTo`, use the part's modifier.
     */
    as?: TagName
    /** @internal Bound by the provider. */
    spec: PartSpec
    /** @internal Bound by the provider. */
    owner: string
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** A part with nothing of its own to track: a header, a group, a menu, an item. */
const SidebarPart: TOC<SidebarPartSignature> = <template>
  <As
    @as={{@as}}
    @tag={{@spec.tag}}
    class={{@spec.class}}
    data-slot={{attributeOf @spec @owner "data-slot"}}
    data-sidebar={{attributeOf @spec @owner "data-sidebar"}}
    data-test-jn-part={{attributeOf @spec @owner "data-test-jn-part"}}
    data-test-jn-owner={{attributeOf @spec @owner "data-test-jn-owner"}}
    ...attributes
  >{{yield}}</As>
</template>

// ----- The provider ---------------------------------------------------------------------------

export interface SidebarProviderSignature {
  Args: {
    /** Whether the sidebar is open, controlled. Pass `@onOpenChange` too, to hear it change. */
    open?: boolean
    /** Whether it starts open, uncontrolled. Default `true`. */
    defaultOpen?: boolean
    /** Called with each new open state (the desktop sidebar's; the mobile sheet's is its own). */
    onOpenChange?: (open: boolean) => void
    /**
     * The key that, with ⌘ or Ctrl, opens and closes the sidebar. Default `b`, as upstream's
     * `SIDEBAR_KEYBOARD_SHORTCUT`; `false` for none.
     */
    keyboardShortcut?: string | false
    /**
     * The viewport width, in CSS pixels, below which the sidebar is a sheet. Default 768, as
     * upstream's `use-mobile` hook. Make it 768 or wider: the desktop sidebar's CSS, as
     * upstream's, shows it only from Tailwind's `md` breakpoint (768px) up, so below 768 it
     * would leave a window between the two with neither sheet nor sidebar.
     */
    mobileBreakpoint?: number
    /**
     * The cookie the open state is kept in, each time it changes, as upstream's
     * `SIDEBAR_COOKIE_NAME`. Default `sidebar_state`; `false` keeps no cookie. Read it back with
     * `sidebarStateFromCookie()`.
     */
    cookieName?: string | false
    /** Its name, for `SidebarHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [SidebarBlockParams] }
  Element: HTMLDivElement
}

/**
 * Provides the sidebar's state to its parts, and lays out the sidebar and the page beside it:
 * shadcn's `SidebarProvider`. It yields every part, each as a component and as a modifier, and
 * what upstream's `useSidebar()` returns:
 *
 *   <SidebarProvider as |sidebar|>
 *     <sidebar.Sidebar @collapsible="icon">
 *       <sidebar.Header>…</sidebar.Header>
 *       <sidebar.Content>
 *         <sidebar.Group>…</sidebar.Group>
 *       </sidebar.Content>
 *       <sidebar.Footer>…</sidebar.Footer>
 *       <sidebar.Rail />
 *     </sidebar.Sidebar>
 *     <sidebar.Inset>
 *       <sidebar.Trigger />
 *     </sidebar.Inset>
 *   </SidebarProvider>
 *
 * Its open state is its own (open to start with, or `@defaultOpen`), or yours with `@open` and
 * `@onOpenChange`, and each change is kept in a cookie. ⌘B (Ctrl+B) opens and closes it. Below
 * 768px wide the sidebar is a sheet instead, with its own open state.
 */
export class SidebarProvider extends Component<SidebarProviderSignature> {
  openState = controllable(this, 'open', true)

  /** Whether the mobile sheet is open. */
  @tracked openMobile = false

  /** The width of the window the provider renders in, in CSS pixels. */
  @tracked viewportWidth: number

  /** The document the provider renders in, for its cookie (a preview's frame has its own). */
  #document: Document | undefined

  /** The triggers rendered for it (`Trigger`, `{{sidebar.trigger}}`), for focus to go back to. */
  #triggers = new Set<HTMLElement>()

  /** @internal The desktop sidebar it renders, which says how it collapses. */
  panel: { readonly collapsible: SidebarCollapsible } | undefined

  constructor(owner: Owner, args: SidebarProviderSignature['Args']) {
    super(owner, args)
    // The page's own width, so a sidebar first renders as it should; `setup` measures again in
    // the window the provider is in, which differs only inside a frame.
    this.viewportWidth = typeof window === 'undefined' ? Infinity : window.innerWidth
  }

  /**
   * Whether there is a DOM to provide through, for `<UseSidebar>`: `<Provide>` makes its marker
   * with `document`, which a server-side render may not have.
   */
  get hasDocument(): boolean {
    return typeof document !== 'undefined'
  }

  /** The root's `id`, which its parts name as their owner. */
  get id(): string {
    return idFor(this)
  }

  get breakpoint(): number {
    return this.args.mobileBreakpoint ?? SIDEBAR_MOBILE_BREAKPOINT
  }

  get shortcut(): string | false {
    return this.args.keyboardShortcut ?? SIDEBAR_KEYBOARD_SHORTCUT
  }

  /** Whether the desktop sidebar is open. */
  get open(): boolean {
    return this.openState.value
  }

  get state(): SidebarState {
    return this.open ? 'expanded' : 'collapsed'
  }

  /** Opens (`true`) or closes (`false`) the desktop sidebar, and keeps that in the cookie. */
  setOpen = (open: boolean): void => {
    if (!open) this.#keepFocus()
    this.openState.set(open)
    const name = this.args.cookieName ?? SIDEBAR_COOKIE_NAME
    const doc = this.#document ?? (typeof document === 'undefined' ? undefined : document)
    if (name !== false && doc) {
      doc.cookie = `${name}=${open}; path=/; max-age=${SIDEBAR_COOKIE_MAX_AGE}`
    }
  }

  /**
   * Closing, an offcanvas sidebar slides off the screen and hides what is in it (sidebar.css),
   * so focus in it would be lost: it goes to a trigger first. The rail stays where it is, so
   * focus on it does too.
   */
  #keepFocus(): void {
    if (this.isMobile || this.panel?.collapsible !== 'offcanvas') return
    const active = this.#document?.activeElement
    const container = active?.closest('[data-slot="sidebar-container"]')
    if (!active || !container || active.closest('[data-slot="sidebar-rail"]')) return
    if (container.closest('[data-slot="sidebar-wrapper"]')?.id !== this.id) return
    const trigger = [...this.#triggers].find(
      element => element.isConnected && !container.contains(element),
    )
    trigger?.focus()
  }

  /** @internal Keeps a trigger's element, while it renders, for focus to go back to. */
  registerTrigger: PartModifier = part(() => ({
    element: element => {
      this.#triggers.add(element)
      return () => void this.#triggers.delete(element)
    },
  }))

  /** Opens (`true`) or closes (`false`) the mobile sheet. */
  setOpenMobile = (open: boolean): void => {
    this.openMobile = open
  }

  /** Opens the sidebar if it is closed and closes it if it is open: the sheet, on mobile. */
  toggleSidebar = (): void => {
    if (this.isMobile) this.setOpenMobile(!this.openMobile)
    else this.setOpen(!this.open)
  }

  /** Whether the viewport is narrower than the mobile breakpoint, so the sidebar is a sheet. */
  get isMobile(): boolean {
    return this.viewportWidth < this.breakpoint
  }

  /**
   * Watches the window the provider renders in, for its width and the keyboard shortcut. A
   * guide preview renders into a frame narrower than the page, which is this window.
   */
  setup: PartModifier = part(() => ({
    element: element => {
      this.#document = element.ownerDocument
      const view = element.ownerDocument.defaultView
      if (!view) return
      const measure = () => {
        if (!this.isDestroying && view.innerWidth !== this.viewportWidth) {
          this.viewportWidth = view.innerWidth
        }
      }
      // Not during this render, which has read the width already.
      if (view.innerWidth !== this.viewportWidth) queueMicrotask(measure)
      const onKeyDown = (event: KeyboardEvent) => {
        const shortcut = this.shortcut
        if (!shortcut || event.key !== shortcut || !(event.metaKey || event.ctrlKey)) return
        event.preventDefault()
        this.toggleSidebar()
      }
      view.addEventListener('resize', measure)
      view.addEventListener('keydown', onKeyDown)
      return () => {
        view.removeEventListener('resize', measure)
        view.removeEventListener('keydown', onKeyDown)
      }
    },
  }))

  // The parts' modifiers, for an element or component of your own.
  header = partModifier(HEADER, this)
  footer = partModifier(FOOTER, this)
  content = partModifier(CONTENT, this)
  group = partModifier(GROUP, this)
  groupLabel = partModifier(GROUP_LABEL, this)
  groupAction = partModifier(GROUP_ACTION, this)
  groupContent = partModifier(GROUP_CONTENT, this)
  menu = partModifier(MENU, this)
  menuItem = partModifier(MENU_ITEM, this)
  menuBadge = partModifier(MENU_BADGE, this)
  menuSub = partModifier(MENU_SUB, this)
  menuSubItem = partModifier(MENU_SUB_ITEM, this)
  inset = partModifier(INSET, this)

  /** Makes your own element a menu action: `<button {{sidebar.menuAction showOnHover=true}}>`. */
  menuAction: PartModifier<HTMLElement, SidebarMenuActionOptions> = part<
    HTMLElement,
    SidebarMenuActionOptions
  >(options => ({
    class: MENU_ACTION_CLASS,
    attributes: menuActionAttributes(options),
  }))

  /**
   * Makes your own element or component a trigger: it opens and closes the sidebar, and says
   * whether it is open (`aria-expanded`). It adds `jn-sidebar-trigger`, so a ghost Button keeps
   * its resting look while the sidebar is open, as `Trigger` does.
   */
  trigger: PartModifier = part(() => ({
    class: TRIGGER_CLASS,
    attributes: triggerAttributes(this),
    on: { click: () => this.toggleSidebar() },
    element: element => {
      this.#triggers.add(element)
      return () => void this.#triggers.delete(element)
    },
  }))

  <template>
    <div
      id={{this.id}}
      class="jn-sidebar-wrapper group/sidebar-wrapper"
      data-slot="sidebar-wrapper"
      data-test-jn="sidebar"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.setup}}
    >
      {{#if this.hasDocument}}
        {{! What upstream's components find through React's context: a routed page's <UseSidebar>. }}
        <Provide @data={{this}} @key={{SidebarProvider}} @element={{false}}>
          <SidebarParts @sidebar={{this}} as |sidebar|>{{yield sidebar}}</SidebarParts>
        </Provide>
      {{else}}
        <SidebarParts @sidebar={{this}} as |sidebar|>{{yield sidebar}}</SidebarParts>
      {{/if}}
    </div>
  </template>
}

/** A part's modifier, with the provider's id as the owner it names. */
function partModifier(part_: PartSpec, provider: SidebarProvider): PartModifier<HTMLElement> {
  return part<HTMLElement>(() => ({
    class: part_.class,
    attributes: partAttributes(part_, provider.id),
  }))
}

/** What a trigger says of the sidebar: whether it is open, and that it is the sidebar's. */
function triggerAttributes(provider: SidebarProvider): Record<string, string> {
  const expanded = provider.isMobile ? provider.openMobile : provider.open
  return {
    'aria-expanded': expanded ? 'true' : 'false',
    'data-test-jn-part': 'trigger',
    'data-test-jn-owner': provider.id,
  }
}

// ----- The sidebar itself ---------------------------------------------------------------------

export interface SidebarSignature {
  Args: {
    /** The side of the screen it is on. Default `left`. */
    side?: SidebarSide
    /** How it looks. Default `sidebar`; with `inset`, put the page in the `Inset`. */
    variant?: SidebarVariant
    /** How it closes. Default `offcanvas`. */
    collapsible?: SidebarCollapsible
    /** The mobile sheet's title, for screen readers. Default `Sidebar`. */
    mobileTitle?: string
    /** The mobile sheet's description, for screen readers. Default `Displays the mobile sidebar.` */
    mobileDescription?: string
    /** @internal Bound by the provider. */
    sidebar: SidebarProvider
  }
  Blocks: { default: [] }
  /**
   * The element your attributes go on: the panel inside (`data-slot="sidebar-container"`), as
   * upstream's `className` does; the panel itself with `@collapsible="none"`; the sheet on
   * mobile.
   */
  Element: HTMLDivElement
}

class SidebarPanel extends Component<SidebarSignature> {
  constructor(owner: Owner, args: SidebarSignature['Args']) {
    super(owner, args)
    const sidebar = args.sidebar
    sidebar.panel = this
    registerDestructor(this, () => {
      if (sidebar.panel === this) sidebar.panel = undefined
    })
  }

  get side(): SidebarSide {
    return this.args.side ?? 'left'
  }

  get variant(): SidebarVariant {
    return this.args.variant ?? 'sidebar'
  }

  get collapsible(): SidebarCollapsible {
    return this.args.collapsible ?? 'offcanvas'
  }

  get isStatic(): boolean {
    return this.collapsible === 'none'
  }

  /** Upstream's `data-collapsible`: how it closed, while it is closed, and empty while open. */
  get dataCollapsible(): string {
    return this.args.sidebar.state === 'collapsed' ? this.collapsible : ''
  }

  <template>
    {{#if this.isStatic}}
      <div
        class="jn-sidebar-static"
        data-slot="sidebar"
        data-test-jn-part="sidebar"
        ...attributes
      >{{yield}}</div>
    {{else if @sidebar.isMobile}}
      <Sheet @open={{@sidebar.openMobile}} @onOpenChange={{@sidebar.setOpenMobile}} as |s|>
        <s.Content
          @side={{this.side}}
          @showCloseButton={{false}}
          class="jn-sidebar-mobile"
          data-sidebar="sidebar"
          data-mobile="true"
          ...attributes
        >
          <s.Header {{visuallyHidden}}>
            <s.Title>{{if @mobileTitle @mobileTitle (t messages.sidebarMobileTitle)}}</s.Title>
            <s.Description>{{if
                @mobileDescription
                @mobileDescription
                (t messages.sidebarMobileDescription)
              }}</s.Description>
          </s.Header>
          <div class="jn-sidebar-mobile-inner">{{yield}}</div>
        </s.Content>
      </Sheet>
    {{else}}
      <div
        class="jn-sidebar group peer"
        data-state={{@sidebar.state}}
        data-collapsible={{this.dataCollapsible}}
        data-variant={{this.variant}}
        data-side={{this.side}}
        data-slot="sidebar"
        data-test-jn-part="sidebar"
      >
        {{! What holds the sidebar's room on the page, as upstream's comment says: the gap. }}
        <div class="jn-sidebar-gap" data-slot="sidebar-gap"></div>
        <div
          class="jn-sidebar-container"
          data-slot="sidebar-container"
          data-side={{this.side}}
          ...attributes
        >
          <div class="jn-sidebar-inner" data-sidebar="sidebar" data-slot="sidebar-inner">
            {{yield}}
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}

// ----- The trigger and the rail ---------------------------------------------------------------

export interface SidebarTriggerSignature {
  Args: {
    /** Its name for screen readers. Default `Toggle Sidebar`. */
    label?: string
    /** Its icon: one from `lucide`. Default lucide's `panel-left` (upstream's `PanelLeftIcon`). */
    icon?: IconNode
    /** @internal Bound by the provider. */
    sidebar: SidebarProvider
  }
  /** A ghost, small icon Button. */
  Element: HTMLButtonElement | HTMLAnchorElement
}

/** A button that opens and closes the sidebar: a ghost icon Button, with `aria-expanded`. */
const SidebarTrigger: TOC<SidebarTriggerSignature> = <template>
  {{#let (triggerAttributes @sidebar) as |attributes|}}
    <Button
      @variant="ghost"
      @size="icon-sm"
      class={{TRIGGER_CLASS}}
      data-sidebar="trigger"
      data-slot="sidebar-trigger"
      aria-expanded={{get attributes "aria-expanded"}}
      data-test-jn-part="trigger"
      data-test-jn-owner={{@sidebar.id}}
      ...attributes
      {{on "click" @sidebar.toggleSidebar}}
      {{@sidebar.registerTrigger}}
    >
      <Icon @icon={{if @icon @icon PanelLeft}} class="jn-rtl-flip" />
      <span {{visuallyHidden}}>{{if @label @label (t messages.sidebarToggle)}}</span>
    </Button>
  {{/let}}
</template>

export interface SidebarRailSignature {
  Args: {
    /** Its name for screen readers, and its `title`. Default `Toggle Sidebar`. */
    label?: string
    /** @internal Bound by the provider. */
    sidebar: SidebarProvider
  }
  Element: HTMLButtonElement
}

/**
 * The strip along the sidebar's inner edge: a click opens or closes it. As upstream's, it is
 * out of the tab order (the trigger and the shortcut are the keyboard's ways).
 */
const SidebarRail: TOC<SidebarRailSignature> = <template>
  <button
    class="jn-sidebar-rail"
    data-sidebar="rail"
    data-slot="sidebar-rail"
    aria-label={{if @label @label (t messages.sidebarToggle)}}
    tabindex="-1"
    title={{if @label @label (t messages.sidebarToggle)}}
    data-test-jn-part="rail"
    data-test-jn-owner={{@sidebar.id}}
    ...attributes
    {{on "click" @sidebar.toggleSidebar}}
  ></button>
</template>

// ----- Input, separator and skeleton, on Joinery's own --------------------------------------

export interface SidebarInputSignature {
  Args: NativeValueArgs & {
    /** Its name, for `InputHarness` (`data-test-jn-name`). */
    name?: string
    /** @internal Bound by the provider. */
    sidebar: SidebarProvider
  }
  Element: HTMLInputElement
}

/** An Input, sized for the sidebar. */
const SidebarInput: TOC<SidebarInputSignature> = <template>
  <Input
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @name={{@name}}
    class="jn-sidebar-input"
    data-slot="sidebar-input"
    data-sidebar="input"
    data-test-jn-part="input"
    data-test-jn-owner={{@sidebar.id}}
    ...attributes
  />
</template>

export interface SidebarSeparatorSignature {
  Args: {
    /** Default `horizontal`. */
    orientation?: SeparatorOrientation
    /** Whether assistive technology skips it. Default `true`, as upstream's. */
    decorative?: boolean
    /** @internal Bound by the provider. */
    sidebar: SidebarProvider
  }
  Element: HTMLDivElement
}

function separatorAttributes(
  orientation: SeparatorOrientation | undefined,
  decorative: boolean | undefined,
): Record<string, string | undefined> {
  return separatorAria({
    orientation: orientation ?? 'horizontal',
    decorative: decorative ?? true,
    tag: 'div',
  }) as unknown as Record<string, string | undefined>
}

/**
 * A line between the sidebar's sections: upstream's SidebarSeparator, which renders its
 * Separator, so it is decorative unless you say.
 */
const SidebarSeparator: TOC<SidebarSeparatorSignature> = <template>
  {{#let (separatorAttributes @orientation @decorative) as |aria|}}
    <div
      class="jn-sidebar-separator"
      data-slot="sidebar-separator"
      data-sidebar="separator"
      role={{get aria "role"}}
      aria-orientation={{get aria "aria-orientation"}}
      aria-hidden={{get aria "aria-hidden"}}
      data-orientation={{get aria "data-orientation"}}
      data-test-jn-part="separator"
      data-test-jn-owner={{@sidebar.id}}
      ...attributes
    ></div>
  {{/let}}
</template>

export interface SidebarMenuSkeletonSignature {
  Args: {
    /** Show an icon's placeholder before the text's. */
    showIcon?: boolean
    /** @internal Bound by the provider. */
    sidebar: SidebarProvider
  }
  Element: HTMLDivElement
}

/** Sets a custom property through the CSSOM, which a strict Content Security Policy allows. */
const customProperty: PartModifier<HTMLElement, { name: string; value: string }> = part<
  HTMLElement,
  { name: string; value: string }
>(({ name, value }) => ({
  element: element => {
    element.style.setProperty(name, value)
    return () => element.style.removeProperty(name)
  },
}))

/** A menu item's placeholder while the menu loads: its text a random 50 to 90% wide, as upstream's. */
class SidebarMenuSkeleton extends Component<SidebarMenuSkeletonSignature> {
  width = `${Math.floor(Math.random() * 40) + 50}%`

  <template>
    <div
      class="jn-sidebar-menu-skeleton"
      data-slot="sidebar-menu-skeleton"
      data-sidebar="menu-skeleton"
      data-test-jn-part="menu-skeleton"
      data-test-jn-owner={{@sidebar.id}}
      ...attributes
    >
      {{#if @showIcon}}
        <Skeleton class="jn-sidebar-menu-skeleton-icon" data-sidebar="menu-skeleton-icon" />
      {{/if}}
      <Skeleton
        class="jn-sidebar-menu-skeleton-text"
        data-sidebar="menu-skeleton-text"
        {{customProperty name="--skeleton-width" value=this.width}}
      />
    </div>
  </template>
}

// ----- Menu buttons and actions ---------------------------------------------------------------

/** A menu button's look: what both `MenuButton` and the `menuButton` modifier take. */
export interface SidebarMenuButtonOptions {
  /** Whether it is the current page's: it shows highlighted (`data-active`). Default `false`. */
  isActive?: boolean
  /** Default `default`. */
  variant?: SidebarMenuButtonVariant
  /** Default `default`. */
  size?: SidebarMenuButtonSize
  /** Its name, for `SidebarMenuButtonHarness` (`data-test-jn-name`). */
  name?: string
}

/**
 * The classes a menu button renders: upstream's semantic classes, renamed `jn-`, and the
 * `peer/menu-button` and `group/menu-button` markers its neighbours' rules look for.
 */
export function sidebarMenuButtonClasses({
  variant = 'default',
  size = 'default',
}: SidebarMenuButtonOptions = {}): string {
  return `jn-sidebar-menu-button peer/menu-button group/menu-button jn-sidebar-menu-button-variant-${variant} jn-sidebar-menu-button-size-${size}`
}

/** The attributes a menu button renders: upstream's (`data-active` is `"true"` or `"false"`), and its harness's. */
export function sidebarMenuButtonAttributes({
  isActive = false,
  size = 'default',
  name,
}: SidebarMenuButtonOptions = {}): Record<string, string | undefined> {
  return {
    'data-slot': 'sidebar-menu-button',
    'data-sidebar': 'menu-button',
    'data-size': size,
    'data-active': isActive ? 'true' : 'false',
    'data-test-jn': 'sidebar-menu-button',
    'data-test-jn-name': name,
  }
}

/**
 * Makes your own element or component a menu button, as upstream's `asChild` does:
 * `<LinkTo @route="inbox" {{sidebar.menuButton isActive=true}}>`. It has no tooltip: for one,
 * use `MenuButton` with `@as`.
 */
export const asSidebarMenuButton: PartModifier<HTMLElement, SidebarMenuButtonOptions> = part<
  HTMLElement,
  SidebarMenuButtonOptions
>(options => ({
  class: sidebarMenuButtonClasses(options),
  attributes: sidebarMenuButtonAttributes(options),
}))

export interface SidebarMenuButtonSignature {
  Args: SidebarMenuButtonOptions & {
    /**
     * A tooltip, shown on the right, centred, while the sidebar is collapsed (and not on
     * mobile), for a sidebar that collapses to its icons. Upstream's also takes an object of
     * TooltipContent's props (`side`, `align`, `hidden`, `children`…); Joinery's takes the
     * text only.
     */
    tooltip?: string
    /** The tag to render instead of `button`, such as `a` for a link (`@as="a" href="#"`). */
    as?: TagName
    /** @internal Bound by the provider. */
    sidebar: SidebarProvider
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement | HTMLAnchorElement
}

/**
 * A menu's button or link: its icon and label, highlighted when `@isActive`. A component root
 * of its own (`SidebarMenuButtonHarness`), so it can be a Collapsible's or a Dropdown Menu's
 * trigger too (`<s.MenuButton {{m.trigger}}>`).
 */
class SidebarMenuButton extends Component<SidebarMenuButtonSignature> {
  get options(): SidebarMenuButtonOptions {
    const { isActive, variant, size, name } = this.args
    return { isActive, variant, size, name }
  }

  get classes(): string {
    return sidebarMenuButtonClasses(this.options)
  }

  get attributes(): Record<string, string | undefined> {
    return sidebarMenuButtonAttributes(this.options)
  }

  /** Whether the pointer or focus asks for the tooltip. */
  @tracked tooltipWanted = false

  /**
   * As upstream's, the tooltip shows only while the sidebar is collapsed, and never on mobile.
   * Upstream opens it all the same and hides it; Joinery's stays closed, so it neither repeats
   * the label to a screen reader nor takes the Escape that should close the mobile sheet.
   */
  get tooltipOpen(): boolean {
    const sidebar = this.args.sidebar
    return this.tooltipWanted && sidebar.state === 'collapsed' && !sidebar.isMobile
  }

  setTooltipOpen = (open: boolean): void => {
    this.tooltipWanted = open
  }

  <template>
    {{#if @tooltip}}
      <Tooltip @open={{this.tooltipOpen}} @onOpenChange={{this.setTooltipOpen}} as |t|>
        <As
          @as={{@as}}
          @tag="button"
          class={{this.classes}}
          data-slot={{get this.attributes "data-slot"}}
          data-sidebar={{get this.attributes "data-sidebar"}}
          data-size={{get this.attributes "data-size"}}
          data-active={{get this.attributes "data-active"}}
          data-test-jn={{get this.attributes "data-test-jn"}}
          data-test-jn-name={{get this.attributes "data-test-jn-name"}}
          {{t.trigger}}
          ...attributes
        >{{yield}}</As>
        <t.Content @side="right" @align="center">
          {{@tooltip}}
        </t.Content>
      </Tooltip>
    {{else}}
      <As
        @as={{@as}}
        @tag="button"
        class={{this.classes}}
        data-slot={{get this.attributes "data-slot"}}
        data-sidebar={{get this.attributes "data-sidebar"}}
        data-size={{get this.attributes "data-size"}}
        data-active={{get this.attributes "data-active"}}
        data-test-jn={{get this.attributes "data-test-jn"}}
        data-test-jn-name={{get this.attributes "data-test-jn-name"}}
        ...attributes
      >{{yield}}</As>
    {{/if}}
  </template>
}

/** What the `menuAction` modifier takes. */
export interface SidebarMenuActionOptions {
  /** Show it only while its item is hovered or has focus (on wide screens). Default `false`. */
  showOnHover?: boolean
}

const MENU_ACTION_CLASS = 'jn-sidebar-menu-action'

function menuActionAttributes({ showOnHover }: SidebarMenuActionOptions = {}): Record<
  string,
  string | undefined
> {
  return {
    'data-slot': 'sidebar-menu-action',
    'data-sidebar': 'menu-action',
    'data-show-on-hover': showOnHover ? 'true' : undefined,
    'data-test-jn-part': 'menu-action',
  }
}

export interface SidebarMenuActionSignature {
  Args: SidebarMenuActionOptions & {
    /** The tag to render instead of `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** A button at a menu item's end, such as one that opens the item's own menu. */
const SidebarMenuAction: TOC<SidebarMenuActionSignature> = <template>
  {{#let (menuActionAttributes showOnHover=@showOnHover) as |attributes|}}
    <As
      @as={{@as}}
      @tag="button"
      class={{MENU_ACTION_CLASS}}
      data-slot={{get attributes "data-slot"}}
      data-sidebar={{get attributes "data-sidebar"}}
      data-show-on-hover={{get attributes "data-show-on-hover"}}
      data-test-jn-part={{get attributes "data-test-jn-part"}}
      ...attributes
    >{{yield}}</As>
  {{/let}}
</template>

/** A submenu button's look: what both `MenuSubButton` and the `menuSubButton` modifier take. */
export interface SidebarMenuSubButtonOptions {
  /** Default `md`. */
  size?: SidebarMenuSubButtonSize
  /** Whether it is the current page's: it shows highlighted (`data-active`). Default `false`. */
  isActive?: boolean
  /** Its name, for `SidebarMenuSubButtonHarness` (`data-test-jn-name`). */
  name?: string
}

/** The attributes a submenu button renders: upstream's, and its harness's. */
export function sidebarMenuSubButtonAttributes({
  size = 'md',
  isActive = false,
  name,
}: SidebarMenuSubButtonOptions = {}): Record<string, string | undefined> {
  return {
    'data-slot': 'sidebar-menu-sub-button',
    'data-sidebar': 'menu-sub-button',
    'data-size': size,
    'data-active': isActive ? 'true' : 'false',
    'data-test-jn': 'sidebar-menu-sub-button',
    'data-test-jn-name': name,
  }
}

const SUB_BUTTON_CLASS = 'jn-sidebar-menu-sub-button'

/**
 * Makes your own element or component a submenu button: `<LinkTo {{sidebar.menuSubButton}}>`.
 */
export const asSidebarMenuSubButton: PartModifier<HTMLElement, SidebarMenuSubButtonOptions> = part<
  HTMLElement,
  SidebarMenuSubButtonOptions
>(options => ({
  class: SUB_BUTTON_CLASS,
  attributes: sidebarMenuSubButtonAttributes(options),
}))

export interface SidebarMenuSubButtonSignature {
  Args: SidebarMenuSubButtonOptions & {
    /** The tag to render instead of `a`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLAnchorElement
}

/** A submenu's link (`<a>`): give it `href`, or your own element with `menuSubButton`. */
const SidebarMenuSubButton: TOC<SidebarMenuSubButtonSignature> = <template>
  {{#let (sidebarMenuSubButtonAttributes size=@size isActive=@isActive name=@name) as |attributes|}}
    <As
      @as={{@as}}
      @tag="a"
      class={{SUB_BUTTON_CLASS}}
      data-slot={{get attributes "data-slot"}}
      data-sidebar={{get attributes "data-sidebar"}}
      data-size={{get attributes "data-size"}}
      data-active={{get attributes "data-active"}}
      data-test-jn={{get attributes "data-test-jn"}}
      data-test-jn-name={{get attributes "data-test-jn-name"}}
      ...attributes
    >{{yield}}</As>
  {{/let}}
</template>

// ----- What the provider yields ---------------------------------------------------------------

interface SidebarPartsSignature {
  Args: { sidebar: SidebarProvider }
  Blocks: { default: [SidebarBlockParams] }
}

/** The parts and state a provider yields, and `<UseSidebar>` too, bound to the provider. */
const SidebarParts: TOC<SidebarPartsSignature> = <template>
  {{yield
    (hash
      Sidebar=(component SidebarPanel sidebar=@sidebar)
      Trigger=(component SidebarTrigger sidebar=@sidebar)
      Rail=(component SidebarRail sidebar=@sidebar)
      Inset=(component SidebarPart spec=INSET owner=@sidebar.id)
      Input=(component SidebarInput sidebar=@sidebar)
      Header=(component SidebarPart spec=HEADER owner=@sidebar.id)
      Footer=(component SidebarPart spec=FOOTER owner=@sidebar.id)
      Separator=(component SidebarSeparator sidebar=@sidebar)
      Content=(component SidebarPart spec=CONTENT owner=@sidebar.id)
      Group=(component SidebarPart spec=GROUP owner=@sidebar.id)
      GroupLabel=(component SidebarPart spec=GROUP_LABEL owner=@sidebar.id)
      GroupAction=(component SidebarPart spec=GROUP_ACTION owner=@sidebar.id)
      GroupContent=(component SidebarPart spec=GROUP_CONTENT owner=@sidebar.id)
      Menu=(component SidebarPart spec=MENU owner=@sidebar.id)
      MenuItem=(component SidebarPart spec=MENU_ITEM owner=@sidebar.id)
      MenuButton=(component SidebarMenuButton sidebar=@sidebar)
      MenuAction=SidebarMenuAction
      MenuBadge=(component SidebarPart spec=MENU_BADGE owner=@sidebar.id)
      MenuSkeleton=(component SidebarMenuSkeleton sidebar=@sidebar)
      MenuSub=(component SidebarPart spec=MENU_SUB owner=@sidebar.id)
      MenuSubItem=(component SidebarPart spec=MENU_SUB_ITEM owner=@sidebar.id)
      MenuSubButton=SidebarMenuSubButton
      trigger=@sidebar.trigger
      header=@sidebar.header
      footer=@sidebar.footer
      content=@sidebar.content
      group=@sidebar.group
      groupLabel=@sidebar.groupLabel
      groupAction=@sidebar.groupAction
      groupContent=@sidebar.groupContent
      menu=@sidebar.menu
      menuItem=@sidebar.menuItem
      menuButton=asSidebarMenuButton
      menuAction=@sidebar.menuAction
      menuBadge=@sidebar.menuBadge
      menuSub=@sidebar.menuSub
      menuSubItem=@sidebar.menuSubItem
      menuSubButton=asSidebarMenuSubButton
      inset=@sidebar.inset
      state=@sidebar.state
      open=@sidebar.open
      setOpen=@sidebar.setOpen
      openMobile=@sidebar.openMobile
      setOpenMobile=@sidebar.setOpenMobile
      isMobile=@sidebar.isMobile
      toggleSidebar=@sidebar.toggleSidebar
    )
  }}
</template>

export interface UseSidebarSignature {
  Blocks: { default: [SidebarBlockParams] }
}

/**
 * Upstream's `useSidebar()`, for a component that isn't given the provider's block params: it
 * yields what the nearest `<SidebarProvider>` around it does (its parts, their modifiers and
 * its state). That is how a routed page, rendered through an `{{outlet}}` inside the
 * application's provider, reaches the sidebar:
 *
 *   <UseSidebar as |sidebar|>
 *     <sidebar.Trigger />
 *     {{if sidebar.isMobile "On a phone" "On a wide screen"}}
 *   </UseSidebar>
 *
 * As upstream's hook does, it throws when there is no provider around it.
 */
export const UseSidebar: TOC<UseSidebarSignature> = <template>
  <Consume @key={{SidebarProvider}} as |context|>
    <SidebarParts @sidebar={{context.data}} as |sidebar|>{{yield sidebar}}</SidebarParts>
  </Consume>
</template>

type Part = WithBoundArgs<typeof SidebarPart, 'spec' | 'owner'>

/** What a `<SidebarProvider>` yields: the parts, their modifiers, and upstream's `useSidebar()`. */
export interface SidebarBlockParams {
  /** The sidebar: `@side`, `@variant` and `@collapsible`. */
  Sidebar: WithBoundArgs<typeof SidebarPanel, 'sidebar'>
  /** A button that opens and closes the sidebar. */
  Trigger: WithBoundArgs<typeof SidebarTrigger, 'sidebar'>
  /** The strip along the sidebar's edge that opens and closes it. */
  Rail: WithBoundArgs<typeof SidebarRail, 'sidebar'>
  /** The page beside the sidebar: a `<main>`, inset with `@variant="inset"`. */
  Inset: Part
  /** An Input, sized for the sidebar. */
  Input: WithBoundArgs<typeof SidebarInput, 'sidebar'>
  /** The top of the sidebar, which stays put. */
  Header: Part
  /** The bottom of the sidebar, which stays put. */
  Footer: Part
  /** A line between sections. */
  Separator: WithBoundArgs<typeof SidebarSeparator, 'sidebar'>
  /** What scrolls between the header and the footer. */
  Content: Part
  /** A section: a label, an action, and its content. */
  Group: Part
  /** A group's label (`@as` to make it a button, such as a Collapsible's trigger). */
  GroupLabel: Part
  /** A button beside a group's label. */
  GroupAction: Part
  /** A group's content. */
  GroupContent: Part
  /** A menu: a `<ul>` of items. */
  Menu: Part
  /** A menu's item: an `<li>`. */
  MenuItem: Part
  /** An item's button or link: `@isActive`, `@variant`, `@size`, `@tooltip`. */
  MenuButton: WithBoundArgs<typeof SidebarMenuButton, 'sidebar'>
  /** A button at an item's end: `@showOnHover`. */
  MenuAction: typeof SidebarMenuAction
  /** A count at an item's end. */
  MenuBadge: Part
  /** An item's placeholder while the menu loads: `@showIcon`. */
  MenuSkeleton: WithBoundArgs<typeof SidebarMenuSkeleton, 'sidebar'>
  /** A submenu: a `<ul>` under an item. */
  MenuSub: Part
  /** A submenu's item: an `<li>`. */
  MenuSubItem: Part
  /** A submenu's link: `@size`, `@isActive`. */
  MenuSubButton: typeof SidebarMenuSubButton
  /** Makes your own element or component a trigger. */
  trigger: PartModifier
  header: PartModifier
  footer: PartModifier
  content: PartModifier
  group: PartModifier
  /** Makes your own element a group's label: `<c.Trigger {{sidebar.groupLabel}}>`. */
  groupLabel: PartModifier
  groupAction: PartModifier
  groupContent: PartModifier
  menu: PartModifier
  /** Makes your own element a menu item: `<Collapsible @as="li" {{sidebar.menuItem}}>`. */
  menuItem: PartModifier
  /** Makes your own element or component a menu button: `<LinkTo {{sidebar.menuButton}}>`. */
  menuButton: PartModifier<HTMLElement, SidebarMenuButtonOptions>
  menuAction: PartModifier<HTMLElement, SidebarMenuActionOptions>
  menuBadge: PartModifier
  menuSub: PartModifier
  menuSubItem: PartModifier
  /** Makes your own element or component a submenu button: `<a {{sidebar.menuSubButton}}>`. */
  menuSubButton: PartModifier<HTMLElement, SidebarMenuSubButtonOptions>
  inset: PartModifier
  /** `expanded` or `collapsed`. */
  state: SidebarState
  /** Whether the sidebar is open. */
  open: boolean
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
  /** Whether the mobile sheet is open. */
  openMobile: boolean
  /** Opens (`true`) or closes (`false`) the mobile sheet. */
  setOpenMobile: (open: boolean) => void
  /** Whether the viewport is narrower than the mobile breakpoint, so the sidebar is a sheet. */
  isMobile: boolean
  /** Opens or closes the sidebar: the sheet, on mobile. */
  toggleSidebar: () => void
}
