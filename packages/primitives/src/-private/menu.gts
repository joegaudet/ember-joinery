// What Radix's DropdownMenu and ContextMenu share, its `Menu`: a menu's content (focus, keys,
// typeahead and the pointer's grace area on the way to a submenu), its items, checkbox and radio
// items, labels, groups and separators, and its submenus. dropdown-menu.gts and context-menu.gts
// are the public modules; this file is bundled into them.
//
// The parts find each other through the DOM rather than through what binds them: an item is the
// item of the nearest `role="menu"` above it (a submenu's content is rendered inside its
// parent's, as there is no portal), so `<m.Item>` works at any depth.
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import Modifier, { modifier as functionModifier } from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '../as.gts'
import { controllable, type ControllableArgs } from '../controllable-state.ts'
import { getDirection, type Direction } from '../direction.gts'
import {
  dismissable,
  type DismissReason,
  type FocusOutsideEvent,
  type PointerDownOutsideEvent,
} from '../dismiss.ts'
import { focusFirst } from '../focus.ts'
import { addFocusGuards, createFocusScope, type FocusScopeHandle } from '../focus-scope.gts'
import { inertOthers, type Undo } from '../hide-others.ts'
import { idFor } from '../id.ts'
import { topLayer } from '../layer.ts'
import { link } from '../link-helper.ts'
import { part, type AttributeValue, type PartModifier, type PartSpec } from '../part.ts'
import { Presence } from '../presence.gts'
import { scrollLock } from '../scroll-lock.ts'
import { getNextMatch, isTypeaheadKey, Typeahead } from '../typeahead.ts'
import { anchor, type AnchorOptions, type Side, type VirtualElement } from '../anchor/index.ts'
import {
  Delay,
  ElementRef,
  PopperArrow,
  ensureId,
  exposeProperties,
  isPointInPolygon,
  popperOptions,
  type Point,
  type PopperContentArgs,
} from './popper.gts'

// ----- Keys ----------------------------------------------------------------------------------

const SELECTION_KEYS = ['Enter', ' ']
const FIRST_KEYS = ['ArrowDown', 'PageUp', 'Home']
const LAST_KEYS = ['ArrowUp', 'PageDown', 'End']
const FIRST_LAST_KEYS = [...FIRST_KEYS, ...LAST_KEYS]
/** The keys that open a submenu from its trigger, as Radix's: the arrow pointing into it. */
const SUB_OPEN_KEYS: Record<Direction, string[]> = {
  ltr: [...SELECTION_KEYS, 'ArrowRight'],
  rtl: [...SELECTION_KEYS, 'ArrowLeft'],
}
/** The keys that close a submenu from inside it: the arrow pointing back to its trigger. */
const SUB_CLOSE_KEYS: Record<Direction, string[]> = { ltr: ['ArrowLeft'], rtl: ['ArrowRight'] }

const ITEM = '[role="menuitem"], [role="menuitemcheckbox"], [role="menuitemradio"]'
const MENU = '[role="menu"]'

// ----- State --------------------------------------------------------------------------------

/** A checkbox item's state: checked, unchecked, or `indeterminate` (shown as mixed). */
export type MenuCheckedState = boolean | 'indeterminate'

/** Radix's `data-state` for a checked state. */
export function checkedState(checked: MenuCheckedState): 'checked' | 'unchecked' | 'indeterminate' {
  if (checked === 'indeterminate') return 'indeterminate'
  return checked ? 'checked' : 'unchecked'
}

/** A level of a menu, the root or a submenu, as its content and its own submenus see it. */
export interface MenuLevel {
  /** Whether it is open (a submenu: and every menu it is in). */
  readonly isOpen: boolean
}

/**
 * What every part of a menu reads from its root: a dropdown menu, a context menu, or (later) a
 * menubar's menu. dropdown-menu.gts and context-menu.gts each implement it.
 */
export interface MenuRoot extends MenuLevel {
  /** The root's id, which its contents name as their owner (`data-test-jn-owner`). */
  readonly id: string
  /** Whether it is modal: the rest of the page ignores the pointer and focus stays inside. */
  readonly isModal: boolean
  /** `@dir`, when it was given: it wins over the document's direction. */
  readonly explicitDir: Direction | undefined
  /** The name its contents' custom properties use: `dropdown-menu` (`--radix-dropdown-menu-…`). */
  readonly cssName: string
  /** Whether the user is using the keyboard, as Radix's root tracks it. */
  readonly isUsingKeyboard: boolean
  /** Closes the whole menu, as selecting an item does. */
  close(): void
}

/**
 * Whether the user is using the keyboard, as Radix's Menu tracks it for each root: a key press
 * turns it on, and the pointer going down or moving turns it off. A menu opened by the keyboard
 * moves focus to its first item, and one opened by the pointer doesn't.
 */
export class KeyboardIntent {
  isUsingKeyboard = false

  constructor(owner: object) {
    const document = globalThis.document
    const onPointer = () => (this.isUsingKeyboard = false)
    const onKeyDown = () => {
      this.isUsingKeyboard = true
      document.addEventListener('pointerdown', onPointer, { capture: true, once: true })
      document.addEventListener('pointermove', onPointer, { capture: true, once: true })
    }
    document.addEventListener('keydown', onKeyDown, { capture: true })
    registerDestructor(owner, () => {
      document.removeEventListener('keydown', onKeyDown, { capture: true })
      document.removeEventListener('pointerdown', onPointer, { capture: true })
      document.removeEventListener('pointermove', onPointer, { capture: true })
    })
  }
}

// ----- Content ------------------------------------------------------------------------------

/** The polygon a pointer may cross on its way from a submenu's trigger to its content. */
interface GraceIntent {
  area: Point[]
  side: Side | undefined
}

/** Whether an event came from a mouse: Radix's menus ignore pens and touch for hover. */
function isMouse(event: PointerEvent): boolean {
  return event.pointerType === 'mouse'
}

/** The text an item matches typeahead with: `@textValue`, or its own text, trimmed. */
const textValues = new WeakMap<Element, string>()

function textOf(item: HTMLElement): string {
  return textValues.get(item) ?? (item.textContent ?? '').replace(/\s+/g, ' ').trim()
}

function isDisabled(item: Element): boolean {
  return item.hasAttribute('data-disabled')
}

/** The menu content an element is in: the nearest `role="menu"` above it. */
function contentElementOf(element: Element): HTMLElement | null {
  return element.closest<HTMLElement>(MENU)
}

const contents = new WeakMap<Element, MenuContentState>()

/** The state of the menu content an element is in, if it is in one. */
function contentOf(element: Element): MenuContentState | undefined {
  const content = contentElementOf(element)
  return content ? contents.get(content) : undefined
}

/**
 * One menu content's behaviour, as Radix's `MenuContentImpl`: the arrow keys, Home and End
 * between its items, typeahead, Tab kept inside, focus moving to the first item when the
 * keyboard opened it, and the pointer's grace area towards a submenu. It listens on the
 * content's element, so it hears its items' events as they bubble.
 */
export class MenuContentState {
  readonly element: HTMLElement
  readonly level: MenuLevel
  readonly root: MenuRoot
  readonly #loop: () => boolean
  readonly #typeahead = new Typeahead()
  #pointerDir: 'left' | 'right' = 'right'
  #lastPointerX = 0
  #graceIntent: GraceIntent | null = null
  #graceTimer: ReturnType<typeof setTimeout> | undefined

  constructor(
    element: HTMLElement,
    level: MenuLevel,
    root: MenuRoot,
    { loop }: { loop: () => boolean },
  ) {
    this.element = element
    this.level = level
    this.root = root
    this.#loop = loop
  }

  /** Starts listening; returns the cleanup. */
  install(): () => void {
    const { element } = this
    contents.set(element, this)
    const onKeyDown = (event: KeyboardEvent) => this.#onKeyDown(event)
    const onPointerMove = (event: PointerEvent) => this.#onPointerMove(event)
    const onFocusIn = (event: FocusEvent) => this.#onFocusIn(event)
    const onFocusOut = (event: FocusEvent) => {
      const next = event.relatedTarget
      if (!(next instanceof Node) || !element.contains(next)) this.#typeahead.reset()
    }
    element.addEventListener('keydown', onKeyDown)
    element.addEventListener('pointermove', onPointerMove)
    element.addEventListener('focusin', onFocusIn)
    element.addEventListener('focusout', onFocusOut)
    return () => {
      element.removeEventListener('keydown', onKeyDown)
      element.removeEventListener('pointermove', onPointerMove)
      element.removeEventListener('focusin', onFocusIn)
      element.removeEventListener('focusout', onFocusOut)
      this.#typeahead.dispose()
      clearTimeout(this.#graceTimer)
      if (contents.get(element) === this) contents.delete(element)
    }
  }

  /** Its own items (not a submenu's), in order, the disabled ones too. */
  allItems(): HTMLElement[] {
    return [...this.element.querySelectorAll<HTMLElement>(ITEM)].filter(
      item => contentElementOf(item) === this.element,
    )
  }

  /** Its items focus can go to, in order. */
  items(): HTMLElement[] {
    return this.allItems().filter(item => !isDisabled(item))
  }

  /** Whether a search is under way, so Space types rather than presses the item. */
  get isTypingAhead(): boolean {
    return this.#typeahead.isTyping
  }

  /** Focuses the first item, or the last (`reverse`), as Radix's `focusFirst`. */
  focusEdge(last = false): void {
    const items = this.items()
    if (last) items.reverse()
    focusFirst(items, { preventScroll: true })
  }

  #onKeyDown(event: KeyboardEvent): void {
    if (event.defaultPrevented) return
    const target = event.target as HTMLElement
    const content = this.element
    // A key in a submenu inside this content bubbles here too; it is that submenu's.
    const isInside = contentElementOf(target) === content
    if (isInside) {
      if (event.key === 'Tab') event.preventDefault()
      if (isTypeaheadKey(event)) this.#typeAhead(event.key)
      if (target !== content && target.matches(ITEM)) this.#moveFocus(event, target)
    }
    if (target !== content || !FIRST_LAST_KEYS.includes(event.key)) return
    event.preventDefault()
    this.focusEdge(LAST_KEYS.includes(event.key))
  }

  /** The arrow keys, Home and End, between the items, as Radix's vertical roving focus. */
  #moveFocus(event: KeyboardEvent, item: HTMLElement): void {
    if (event.defaultPrevented) return
    const intent = INTENTS[event.key]
    if (!intent) return
    if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) return
    event.preventDefault()
    let candidates = this.items()
    if (intent === 'last') candidates.reverse()
    else if (intent === 'prev' || intent === 'next') {
      if (intent === 'prev') candidates.reverse()
      const index = candidates.indexOf(item)
      candidates = this.#loop()
        ? candidates.map((_, offset) => candidates[(index + 1 + offset) % candidates.length]!)
        : candidates.slice(index + 1)
    }
    focusFirst(candidates)
  }

  #typeAhead(key: string): void {
    const items = this.items()
    const active = document.activeElement
    const current = items.find(item => item === active)
    const match = getNextMatch(items, this.#typeahead.type(key), current, textOf)
    match?.focus()
  }

  /**
   * Focus on the content itself, not an item: move on to the first item when the keyboard is
   * in use, as Radix's roving focus does on entry. The pointer leaves focus on the content.
   */
  #onFocusIn(event: FocusEvent): void {
    if (event.target !== this.element || !this.root.isUsingKeyboard) return
    this.focusEdge()
  }

  #onPointerMove(event: PointerEvent): void {
    if (!isMouse(event)) return
    const target = event.target as Element
    if (contentElementOf(target) !== this.element || this.#lastPointerX === event.clientX) return
    this.#pointerDir = event.clientX > this.#lastPointerX ? 'right' : 'left'
    this.#lastPointerX = event.clientX
  }

  // ----- The pointer's grace area, as Radix's menu works it out ----------------------------

  /** Whether the pointer is heading into the submenu that is opening, through its grace area. */
  isPointerMovingToSubmenu(event: PointerEvent): boolean {
    const intent = this.#graceIntent
    if (!intent || this.#pointerDir !== intent.side) return false
    return isPointInPolygon({ x: event.clientX, y: event.clientY }, intent.area)
  }

  setGraceIntent(intent: GraceIntent | null, clearAfter?: number): void {
    this.#graceIntent = intent
    clearTimeout(this.#graceTimer)
    this.#graceTimer =
      clearAfter === undefined
        ? undefined
        : setTimeout(() => (this.#graceIntent = null), clearAfter)
  }

  // Radix's cancel the pointer event to say "on its way to a submenu", which React's events
  // allow even when the browser's can't be cancelled (`pointerleave`); these return it instead.

  /** The pointer moved onto an item: on its way to a submenu, it doesn't take focus (`true`). */
  onItemEnter(event: PointerEvent): boolean {
    return this.isPointerMovingToSubmenu(event)
  }

  /** The pointer left an item: focus goes back to the content, unless it is on its way to a submenu. */
  onItemLeave(event: PointerEvent): void {
    if (this.isPointerMovingToSubmenu(event)) return
    this.element.focus({ preventScroll: true })
  }

  /** The pointer left a submenu's trigger: whether it is on its way to an open submenu. */
  onTriggerLeave(event: PointerEvent): boolean {
    return this.isPointerMovingToSubmenu(event)
  }
}

const INTENTS: Record<string, 'first' | 'last' | 'prev' | 'next'> = {
  ArrowUp: 'prev',
  ArrowDown: 'next',
  PageUp: 'first',
  Home: 'first',
  PageDown: 'last',
  End: 'last',
}

// ----- Content modifiers ----------------------------------------------------------------------

interface MenuFocusSignature {
  Element: HTMLElement
  Args: {
    Named: {
      enabled: boolean
      trapped: boolean
      onMountAutoFocus: (event: Event) => void
      onUnmountAutoFocus: (event: Event) => void
    }
  }
}

/**
 * A content's focus scope, as Radix's menu has it: it takes focus in when it opens (the content
 * decides where), keeps it inside while a modal menu is open, and decides where it goes when it
 * closes; with focus guards at the ends of `<body>` meanwhile. One scope for the content's life.
 */
export class MenuFocus extends Modifier<MenuFocusSignature> {
  #scope: FocusScopeHandle | undefined
  #releaseGuards: (() => void) | undefined
  #installed = false

  override modify(
    element: HTMLElement,
    _: [],
    { enabled, trapped, onMountAutoFocus, onUnmountAutoFocus }: MenuFocusSignature['Args']['Named'],
  ): void {
    if (!this.#installed) {
      this.#installed = true
      registerDestructor(this, () => this.#stop())
    }
    const options = { trapped, loop: false, onMountAutoFocus, onUnmountAutoFocus }
    if (!enabled) return this.#stop()
    if (this.#scope) return this.#scope.update(options)
    this.#releaseGuards = addFocusGuards()
    this.#scope = createFocusScope(element, options)
  }

  #stop(): void {
    this.#scope?.destroy()
    this.#scope = undefined
    this.#releaseGuards?.()
    this.#releaseGuards = undefined
  }
}

interface InertOutsideSignature {
  Element: HTMLElement
  Args: { Named: { enabled: boolean } }
}

/**
 * While a modal menu is open, makes the rest of the page inert (its submenus are inside its
 * content): nothing there can be focused or read by assistive technology. Radix's modal menu
 * hides the page with `aria-hidden` instead, which leaves its buttons focusable but hidden, as
 * axe reports; `inert` is what a modal `<dialog>` does, as Joinery's Dialog. A press there still
 * reaches the document, so it closes the menu.
 */
export class InertOutside extends Modifier<InertOutsideSignature> {
  #undo: Undo | undefined
  #installed = false

  override modify(element: HTMLElement, _: [], { enabled }: { enabled: boolean }): void {
    if (!this.#installed) {
      this.#installed = true
      registerDestructor(this, () => this.#release())
    }
    if (!enabled) return this.#release()
    this.#undo ??= inertOthers(element)
  }

  #release(): void {
    this.#undo?.()
    this.#undo = undefined
  }
}

interface AnchorMenuSignature {
  Element: HTMLElement
  Args: {
    Positional: [reference: Element | VirtualElement | null | undefined, options: AnchorOptions]
  }
}

/** Anchors a content to its reference (an element, or a context menu's point), again on change. */
export const anchorMenu = functionModifier<AnchorMenuSignature>((element, [reference, options]) => {
  if (!reference || reference === element) return
  return anchor(element, reference, options)
})

// ----- Items --------------------------------------------------------------------------------

/** The arguments every item takes, as its part modifier's named arguments too. */
export interface MenuItemOptions {
  /** Whether it is disabled: it can't be focused or selected, and typeahead skips it. */
  disabled?: boolean
  /**
   * Called when it is selected (a click, Enter or Space), with a cancelable event:
   * `event.preventDefault()` keeps the menu open.
   */
  onSelect?: (event: Event) => void
  /** The text typeahead matches, when its own text isn't right (an icon, extra text). */
  textValue?: string
}

/** Items a pointer went down on, so the pointer coming up doesn't select them twice. */
const pressed = new WeakSet<Element>()

/** Selects an item, as Radix's `MenuItem` does: `onSelect`, then the menu closes unless it was prevented. */
function select(
  root: MenuRoot,
  item: HTMLElement,
  { disabled, onSelect }: MenuItemOptions,
  internal?: () => void,
): void {
  if (disabled) return
  const event = new CustomEvent('menu.itemSelect', { bubbles: true, cancelable: true })
  item.addEventListener(
    'menu.itemSelect',
    selected => {
      onSelect?.(selected)
      internal?.()
    },
    { once: true },
  )
  item.dispatchEvent(event)
  if (event.defaultPrevented) pressed.delete(item)
  else root.close()
}

/** The listeners an item and a submenu's trigger both have: pointer focus, highlight, disabled presses. */
function hoverListeners(disabled: boolean): PartSpec['on'] {
  return {
    pointermove: event => {
      if (!isMouse(event)) return
      const item = event.currentTarget as HTMLElement
      const content = contentOf(item)
      if (disabled) return content?.onItemLeave(event)
      if (!content?.onItemEnter(event)) item.focus({ preventScroll: true })
    },
    pointerleave: event => {
      if (isMouse(event)) contentOf(event.currentTarget as HTMLElement)?.onItemLeave(event)
    },
    // A disabled item takes no focus from a click either.
    mousedown: event => {
      if (disabled) event.preventDefault()
    },
    focus: event => (event.currentTarget as HTMLElement).setAttribute('data-highlighted', ''),
    blur: event => (event.currentTarget as HTMLElement).removeAttribute('data-highlighted'),
  }
}

/** What an item's part sets, whatever its role: `menuitem`, `menuitemcheckbox`, `menuitemradio`. */
export function itemSpec(
  root: MenuRoot,
  options: MenuItemOptions,
  { part: partName, role, attributes = {}, onSelect }: ItemKind,
): PartSpec<HTMLElement> {
  const disabled = options.disabled ?? false
  return {
    attributes: {
      role,
      tabindex: '-1',
      'aria-disabled': disabled ? 'true' : undefined,
      'data-disabled': disabled ? '' : undefined,
      'data-test-jn-part': partName,
      ...attributes,
    },
    on: {
      ...hoverListeners(disabled),
      click: event => select(root, event.currentTarget as HTMLElement, options, onSelect),
      pointerdown: event => void pressed.add(event.currentTarget as HTMLElement),
      // Pressed elsewhere (on the trigger) and let go here: select it, as Radix's menus do.
      pointerup: event => {
        const item = event.currentTarget as HTMLElement
        if (!pressed.has(item)) item.click()
        pressed.delete(item)
      },
      keydown: event => {
        const item = event.currentTarget as HTMLElement
        if (disabled) return
        if (contentOf(item)?.isTypingAhead && event.key === ' ') return
        if (!SELECTION_KEYS.includes(event.key)) return
        item.click()
        event.preventDefault()
      },
    },
  }
}

interface ItemKind {
  part: string
  role: 'menuitem' | 'menuitemcheckbox' | 'menuitemradio'
  attributes?: Record<string, string | undefined>
  onSelect?: () => void
}

/**
 * A part modifier that also keeps the item's `textValue` for typeahead: `part()`'s spec sees
 * only the arguments, not the element.
 */
function withTextValue<Named extends MenuItemOptions>(
  Base: PartModifier<HTMLElement, Named>,
): PartModifier<HTMLElement, Named> {
  return class extends Base {
    override modify(element: HTMLElement, positional: [], named: Named): void {
      if (named.textValue === undefined) textValues.delete(element)
      else textValues.set(element, named.textValue)
      super.modify(element, positional, named)
    }
  }
}

/** A plain item's modifier: `<a {{m.item}}>`, `<LinkTo {{m.item onSelect=…}}>`. */
/**
 * What a styled layer adds to an item's modifier: its classes and attributes (`data-slot`,
 * `data-variant`…), from the modifier's own arguments.
 */
export type MenuItemLook<Named> = (named: Named) => {
  class?: string
  attributes?: Readonly<Record<string, AttributeValue>>
}

function withLook<Named>(
  spec: PartSpec<HTMLElement>,
  named: Named,
  look: MenuItemLook<Named> | undefined,
): PartSpec<HTMLElement> {
  if (!look) return spec
  const extra = look(named)
  return { ...spec, class: extra.class, attributes: { ...extra.attributes, ...spec.attributes } }
}

/**
 * A plain item's modifier for a menu's root: `<a {{m.item}}>`, `<LinkTo {{m.item onSelect=…}}>`.
 * A styled layer passes its `look`, so the modifier renders what its Item does.
 */
export function itemPart<Named extends MenuItemOptions = MenuItemOptions>(
  root: MenuRoot,
  look?: MenuItemLook<Named>,
): PartModifier<HTMLElement, Named> {
  return withTextValue(
    part<HTMLElement, Named>(options =>
      withLook(itemSpec(root, options, { part: 'item', role: 'menuitem' }), options, look),
    ),
  )
}

/** What a checkbox item's modifier takes: its state, controlled. */
export interface MenuCheckboxItemOptions extends MenuItemOptions {
  /** Whether it is checked: `true`, `false` or `indeterminate`. Default `false`. */
  checked?: MenuCheckedState
  /** Called with the state it asks for when selected: an indeterminate one asks for `true`. */
  onCheckedChange?: (checked: boolean) => void
}

/** A checkbox item's modifier: `role="menuitemcheckbox"`, its `aria-checked` and `data-state`. */
export function checkboxItemPart<Named extends MenuCheckboxItemOptions = MenuCheckboxItemOptions>(
  root: MenuRoot,
  look?: MenuItemLook<Named>,
): PartModifier<HTMLElement, Named> {
  return withTextValue(
    part<HTMLElement, Named>(options => {
      const checked = options.checked ?? false
      const spec = itemSpec(root, options, {
        part: 'checkbox-item',
        role: 'menuitemcheckbox',
        attributes: {
          'aria-checked': checked === 'indeterminate' ? 'mixed' : String(checked),
          'data-state': checkedState(checked),
        },
        onSelect: () => options.onCheckedChange?.(checked === 'indeterminate' ? true : !checked),
      })
      return withLook(spec, options, look)
    }),
  )
}

/** The parts with no state of their own: a group, a label, a separator. */
export const groupPart = part<HTMLElement>(() => ({
  attributes: { role: 'group', 'data-test-jn-part': 'group' },
}))

export const labelPart = part<HTMLElement>(() => ({
  attributes: { 'data-test-jn-part': 'label' },
}))

export const separatorPart = part<HTMLElement>(() => ({
  attributes: {
    role: 'separator',
    'aria-orientation': 'horizontal',
    'data-test-jn-part': 'separator',
  },
}))

// ----- The part components ------------------------------------------------------------------

export interface MenuItemSignature {
  Args: MenuItemOptions & {
    /** @internal The item modifier, bound by the menu. */
    part: PartModifier<HTMLElement, MenuItemOptions>
    /** The tag to render. Default `div`, as Radix's. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** An item: selecting it calls `@onSelect` and closes the menu. */
export const MenuItem: TOC<MenuItemSignature> = <template>
  <As
    @as={{@as}}
    @tag="div"
    ...attributes
    {{@part disabled=@disabled onSelect=@onSelect textValue=@textValue}}
  >{{yield}}</As>
</template>

export interface MenuLinkItemSignature {
  Args: MenuItemOptions & {
    /** @internal The item modifier, bound by the menu. */
    part: PartModifier<HTMLElement, MenuItemOptions>
    /** Where it goes. A link to one of the app's routes is a transition, not a page load. */
    href: string
    /** Whether the query params count towards its being active (`data-active`). */
    includeActiveQueryParams?: boolean | string[]
    /** Whether it is active on the routes below it too. */
    activeOnSubPaths?: boolean
  }
  Blocks: { default: [{ isActive: boolean; isExternal: boolean }] }
  Element: HTMLAnchorElement
}

/**
 * ember-primitives' `LinkItem`: an item that is a link, active-aware (`data-active`,
 * `aria-current`), opening a link to another origin in a new tab. Selecting it closes the menu
 * and follows the link.
 */
export const MenuLinkItem: TOC<MenuLinkItemSignature> = <template>
  {{#let
    (link
      @href includeActiveQueryParams=@includeActiveQueryParams activeOnSubPaths=@activeOnSubPaths
    )
    as |l|
  }}
    {{#if l.isExternal}}
      <a
        href={{@href}}
        target="_blank"
        rel="noreferrer noopener"
        ...attributes
        {{@part disabled=@disabled onSelect=@onSelect textValue=@textValue}}
      >{{yield (hash isActive=false isExternal=true)}}</a>
    {{else}}
      <a
        href={{@href}}
        data-active={{l.isActive}}
        aria-current={{if l.isActive (if @activeOnSubPaths "true" "page")}}
        ...attributes
        {{@part disabled=@disabled onSelect=@onSelect textValue=@textValue}}
        {{on "click" l.handleClick}}
      >{{yield (hash isActive=l.isActive isExternal=false)}}</a>
    {{/if}}
  {{/let}}
</template>

export interface MenuItemIndicatorSignature {
  Args: {
    /** @internal The item's state, bound by the item. */
    checked: MenuCheckedState
    /** Keep it rendered while unchecked, for animating it yourself. */
    forceMount?: boolean
  }
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

function shows(checked: MenuCheckedState, forceMount: boolean | undefined): boolean {
  return Boolean(forceMount) || checked === true || checked === 'indeterminate'
}

/** Radix's `ItemIndicator`: a `<span>` shown while its item is checked (or indeterminate). */
export const MenuItemIndicator: TOC<MenuItemIndicatorSignature> = <template>
  <Presence @present={{shows @checked @forceMount}} as |presence|>
    <span
      data-state={{checkedState @checked}}
      data-test-jn-part="item-indicator"
      ...attributes
      {{presence.ref}}
    >{{yield}}</span>
  </Presence>
</template>

/** What a checkbox item yields: its indicator, bound to its state, and the state. */
export interface MenuCheckboxItemBlockParams {
  /** Shown while it is checked: put the check mark in it. */
  Indicator: WithBoundArgs<typeof MenuItemIndicator, 'checked'>
  /** Its state. */
  checked: MenuCheckedState
}

export interface MenuCheckboxItemSignature {
  Args: MenuItemOptions & {
    /** @internal The checkbox item modifier, bound by the menu. */
    part: PartModifier<HTMLElement, MenuCheckboxItemOptions>
    /** Whether it is checked: `true`, `false` or `indeterminate`. Default `false`. */
    checked?: MenuCheckedState
    /** Called with the state it asks for when selected: an indeterminate one asks for `true`. */
    onCheckedChange?: (checked: boolean) => void
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [MenuCheckboxItemBlockParams] }
  Element: HTMLElement
}

/**
 * A checkbox item: selecting it asks for the other state (an indeterminate one, for checked)
 * and closes the menu. As Radix's, its state is yours: `@checked` with `@onCheckedChange`. (A
 * menu's content is gone while it is closed, so it has nowhere to keep a state of its own.)
 */
export class MenuCheckboxItem extends Component<MenuCheckboxItemSignature> {
  get checked(): MenuCheckedState {
    return this.args.checked ?? false
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      ...attributes
      {{@part
        checked=this.checked
        onCheckedChange=@onCheckedChange
        disabled=@disabled
        onSelect=@onSelect
        textValue=@textValue
      }}
    >{{yield
        (hash Indicator=(component MenuItemIndicator checked=this.checked) checked=this.checked)
      }}</As>
  </template>
}

/** What a radio item's modifier takes. */
export interface MenuRadioItemOptions extends MenuItemOptions {
  /** Its value: selecting it makes it the group's. */
  value: string
}

export interface MenuRadioItemSignature {
  Args: MenuItemOptions & {
    /** @internal The group, bound by it. */
    group: MenuRadioGroup
    /** Its value: selecting it makes it the group's. */
    value: string
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: {
    default: [{ Indicator: WithBoundArgs<typeof MenuItemIndicator, 'checked'>; checked: boolean }]
  }
  Element: HTMLElement
}

/** A radio item: selecting it makes its value the group's, and closes the menu. */
export class MenuRadioItem extends Component<MenuRadioItemSignature> {
  get checked(): boolean {
    return this.args.group.value === this.args.value
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      ...attributes
      {{@group.item value=@value disabled=@disabled onSelect=@onSelect textValue=@textValue}}
    >{{yield
        (hash Indicator=(component MenuItemIndicator checked=this.checked) checked=this.checked)
      }}</As>
  </template>
}

/** What a radio group yields: its items, and its value. */
export interface MenuRadioGroupBlockParams {
  /** A radio item of this group: `<g.Item @value="top">Top</g.Item>`. */
  Item: WithBoundArgs<typeof MenuRadioItem, 'group'>
  /** Makes your own element a radio item of this group: `<a {{g.item value="top"}}>`. */
  item: PartModifier<HTMLElement, MenuRadioItemOptions>
  /** Its value. */
  value: string | undefined
}

export interface MenuRadioGroupSignature {
  Args: {
    /** @internal The menu's root, bound by it. */
    menu: MenuRoot
    /** The value of the checked item. */
    value?: string
    /** Called with an item's value when it is selected. */
    onValueChange?: (value: string) => void
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [MenuRadioGroupBlockParams] }
  Element: HTMLElement
}

/**
 * A group of radio items, the one whose value is `@value` checked; selecting another calls
 * `@onValueChange` with its value. As Radix's, its state is yours. A `role="group"`.
 */
export class MenuRadioGroup extends Component<MenuRadioGroupSignature> {
  get value(): string | undefined {
    return this.args.value
  }

  item: PartModifier<HTMLElement, MenuRadioItemOptions> = withTextValue(
    part<HTMLElement, MenuRadioItemOptions>(options => {
      const checked = this.value !== undefined && this.value === options.value
      return itemSpec(this.args.menu, options, {
        part: 'radio-item',
        role: 'menuitemradio',
        attributes: {
          'aria-checked': String(checked),
          'data-state': checkedState(checked),
          'data-test-jn-value': options.value,
        },
        onSelect: () => this.args.onValueChange?.(options.value),
      })
    }),
  )

  <template>
    <As @as={{@as}} @tag="div" role="group" data-test-jn-part="radio-group" ...attributes>{{yield
        (hash Item=(component MenuRadioItem group=this) item=this.item value=this.value)
      }}</As>
  </template>
}

export interface MenuStaticPartSignature {
  Args: {
    /** @internal The part's modifier, bound by the menu. */
    part: PartModifier<HTMLElement>
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** A group of items: a `role="group"`. */
export const MenuGroup: TOC<MenuStaticPartSignature> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@part}}>{{yield}}</As>
</template>

/** A label for the items after it (Radix's is a plain `div`, which nothing names). */
export const MenuLabel: TOC<MenuStaticPartSignature> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@part}}>{{yield}}</As>
</template>

export interface MenuSeparatorSignature {
  Args: { part: PartModifier<HTMLElement>; as?: TagName }
  Element: HTMLElement
}

/** A line between items: a horizontal `role="separator"`. */
export const MenuSeparator: TOC<MenuSeparatorSignature> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@part}} />
</template>

export interface MenuPortalSignature {
  Blocks: { default: [] }
}

/**
 * Radix's `Portal`, kept so upstream's markup ports line for line: it renders its block where
 * it is. A menu's contents are in the top layer, above everything, so they need no portal.
 */
export const MenuPortal: TOC<MenuPortalSignature> = <template>{{yield}}</template>

export interface MenuArrowSignature {
  Args: {
    /** @internal The root content's arrow, bound by the menu. */
    arrow: ElementRef
    /** Its width, in pixels. Default 10. */
    width?: number
    /** Its height, in pixels. Default 5. */
    height?: number
  }
  Blocks: { default: [] }
  Element: SVGSVGElement
}

/** Radix's `Arrow`: an `<svg>` triangle on the content's edge, pointing at the trigger. */
export const MenuArrow: TOC<MenuArrowSignature> = <template>
  {{#if (has-block)}}
    <PopperArrow @arrow={{@arrow}} @width={{@width}} @height={{@height}} ...attributes>
      {{yield}}
    </PopperArrow>
  {{else}}
    <PopperArrow @arrow={{@arrow}} @width={{@width}} @height={{@height}} ...attributes />
  {{/if}}
</template>

// ----- Submenus -----------------------------------------------------------------------------

/** What a submenu's content takes: Radix's Popper arguments but its side, and its handlers. */
export interface MenuSubContentArgs extends Omit<PopperContentArgs, 'side' | 'align'> {
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Keep it rendered while closed, for animating it yourself. */
  forceMount?: boolean
  /** Whether the arrow keys go round from the last item to the first. Default `false`. */
  loop?: boolean
  /** Escape was pressed: it closes the whole menu. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside it. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
  /** Focus moved outside it (it closes, unless that is on its trigger). */
  onFocusOutside?: (event: FocusOutsideEvent) => void
  /** Either of the last two. */
  onInteractOutside?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void
}

export interface MenuSubTriggerSignature {
  Args: Omit<MenuItemOptions, 'onSelect'> & {
    /** @internal The trigger's modifier, bound by the submenu. */
    part: PartModifier<HTMLElement, Omit<MenuItemOptions, 'onSelect'>>
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The item that opens a submenu: hovering it, clicking it, or the arrow pointing into it. */
export const MenuSubTrigger: TOC<MenuSubTriggerSignature> = <template>
  <As
    @as={{@as}}
    @tag="div"
    ...attributes
    {{@part disabled=@disabled textValue=@textValue}}
  >{{yield}}</As>
</template>

export interface MenuSubContentSignature {
  Args: MenuSubContentArgs & {
    /** @internal The submenu, bound by it. */
    sub: MenuSub
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * A submenu's content: beside its trigger (on the right, or the left right to left), aligned
 * with its top, in the top layer while open. ArrowLeft (ArrowRight right to left) goes back to
 * the trigger; Escape closes the whole menu.
 */
export class MenuSubContent extends Component<MenuSubContentSignature> {
  get sub(): MenuSub {
    return this.args.sub
  }

  /** Radix's: beside the trigger, on the side the text reads towards, aligned with its top. */
  get anchorOptions(): AnchorOptions {
    const { sub } = this
    const rtl = getDirection(sub.triggerRef.value, sub.root.explicitDir) === 'rtl'
    const options = popperOptions(this.args, {}, {}, {})
    return { ...options, side: rtl ? 'left' : 'right', align: 'start' }
  }

  get inside(): Array<Element | null> {
    return [this.sub.triggerRef.value]
  }

  contentPart = part<HTMLElement>(() => {
    const { sub } = this
    return {
      attributes: {
        id: sub.contentId,
        role: 'menu',
        'aria-orientation': 'vertical',
        'aria-labelledby': sub.triggerId,
        'data-state': sub.isOpen ? 'open' : 'closed',
        dir: sub.root.explicitDir,
        tabindex: '-1',
        'data-test-jn-part': 'sub-content',
        'data-test-jn-owner': sub.root.id,
      },
      element: element => {
        const restore = exposeProperties(element, sub.root.cssName)
        const state = new MenuContentState(element, sub, sub.root, {
          loop: () => this.args.loop ?? false,
        })
        const uninstall = state.install()
        sub.contentRef.set(element)
        const onKeyDown = (event: KeyboardEvent) => this.#onKeyDown(event, element)
        element.addEventListener('keydown', onKeyDown)
        return () => {
          element.removeEventListener('keydown', onKeyDown)
          sub.contentRef.release(element)
          uninstall()
          restore()
        }
      },
    }
  })

  /** The arrow back towards the trigger closes it and puts focus back there. */
  #onKeyDown(event: KeyboardEvent, element: HTMLElement): void {
    if (event.defaultPrevented) return
    const target = event.target as Node
    const dir = getDirection(element, this.sub.root.explicitDir)
    if (!element.contains(target) || !SUB_CLOSE_KEYS[dir].includes(event.key)) return
    this.sub.setOpen(false)
    this.sub.triggerRef.current?.focus()
    event.preventDefault()
  }

  onOpenAutoFocus = (event: Event): void => {
    // Opened by the keyboard: focus goes in (and on to the first item); by the pointer, it stays.
    if (this.sub.root.isUsingKeyboard) this.sub.contentRef.current?.focus({ preventScroll: true })
    event.preventDefault()
  }

  onCloseAutoFocus = (event: Event): void => event.preventDefault()

  onEscapeKeyDown = (event: KeyboardEvent): void => {
    this.args.onEscapeKeyDown?.(event)
    if (event.defaultPrevented) return
    this.sub.root.close()
    event.preventDefault()
  }

  onFocusOutside = (event: FocusOutsideEvent): void => this.args.onFocusOutside?.(event)

  /** Focus leaving it closes it; a press outside leaves that to the menu it is in. */
  onDismiss = (reason: DismissReason): void => {
    if (reason === 'focus-outside') this.sub.setOpen(false)
  }

  <template>
    <Presence @present={{this.sub.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{presence.ref}}
        {{this.contentPart}}
        {{topLayer}}
        {{anchorMenu this.sub.triggerRef.value this.anchorOptions}}
        {{dismissable
          enabled=this.sub.isOpen
          onDismiss=this.onDismiss
          onEscapeKeyDown=this.onEscapeKeyDown
          onPointerDownOutside=@onPointerDownOutside
          onFocusOutside=this.onFocusOutside
          onInteractOutside=@onInteractOutside
          inside=this.inside
        }}
        {{MenuFocus
          enabled=this.sub.isOpen
          trapped=false
          onMountAutoFocus=this.onOpenAutoFocus
          onUnmountAutoFocus=this.onCloseAutoFocus
        }}
      >{{yield}}</As>
    </Presence>
  </template>
}

/** What a submenu yields: its trigger and content, the trigger's modifier, and its state. */
export interface MenuSubBlockParams {
  /** The item that opens it. */
  Trigger: WithBoundArgs<typeof MenuSubTrigger, 'part'>
  /** Its content, beside the trigger. */
  Content: WithBoundArgs<typeof MenuSubContent, 'sub'>
  /** Makes your own element the item that opens it. */
  trigger: PartModifier<HTMLElement, Omit<MenuItemOptions, 'onSelect'>>
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
}

export interface MenuSubSignature {
  Args: ControllableArgs<'open', boolean> & {
    /** @internal The menu's root, bound by it. */
    menu: MenuRoot
  }
  Blocks: { default: [MenuSubBlockParams] }
}

/**
 * A submenu, as Radix's `Sub`: it yields its Trigger and Content. Its state is its own, or
 * yours (`@open`, `@onOpenChange`, `@defaultOpen`), and it is shown only while every menu it is
 * in is open.
 */
export class MenuSub extends Component<MenuSubSignature> {
  openState = controllable(this, 'open', false)
  triggerRef = new ElementRef()
  contentRef = new ElementRef()
  openTimer = new Delay(this)
  /** The menu it is in, found from its trigger's place once it renders. */
  @tracked parent: MenuLevel | undefined
  #graceTimer: ReturnType<typeof setTimeout> | undefined

  constructor(owner: Owner, args: MenuSubSignature['Args']) {
    super(owner, args)
    registerDestructor(this, () => clearTimeout(this.#graceTimer))
  }

  get root(): MenuRoot {
    return this.args.menu
  }

  get isOpen(): boolean {
    return this.openState.value && (this.parent ?? this.root).isOpen
  }

  get contentId(): string {
    return idFor(this, 'content')
  }

  get triggerId(): string {
    return this.triggerRef.value?.id || idFor(this, 'trigger')
  }

  setOpen = (open: boolean): void => {
    if (!open) this.openTimer.cancel()
    this.openState.set(open)
  }

  trigger: PartModifier<HTMLElement, Omit<MenuItemOptions, 'onSelect'>> = withTextValue(
    part<HTMLElement, Omit<MenuItemOptions, 'onSelect'>>(options => {
      const disabled = options.disabled ?? false
      const open = this.isOpen
      const hover = hoverListeners(disabled)!
      return {
        attributes: {
          role: 'menuitem',
          tabindex: '-1',
          'aria-haspopup': 'menu',
          'aria-expanded': String(open),
          'aria-controls': this.contentId,
          'aria-disabled': disabled ? 'true' : undefined,
          'data-disabled': disabled ? '' : undefined,
          'data-state': open ? 'open' : 'closed',
          'data-test-jn-part': 'sub-trigger',
        },
        on: {
          ...hover,
          click: event => {
            if (disabled) return
            ;(event.currentTarget as HTMLElement).focus()
            if (!this.isOpen) this.setOpen(true)
          },
          pointermove: event => {
            if (!isMouse(event)) return
            const content = contentOf(event.currentTarget as HTMLElement)
            if (content?.onItemEnter(event)) return
            if (!disabled && !this.isOpen && !this.openTimer.isPending) {
              content?.setGraceIntent(null)
              this.openTimer.start(100, () => this.setOpen(true))
            }
            hover.pointermove?.(event)
          },
          pointerleave: event => {
            if (!isMouse(event)) return
            this.openTimer.cancel()
            const content = contentOf(event.currentTarget as HTMLElement)
            const sub = this.contentRef.current
            const rect = sub?.getBoundingClientRect()
            if (sub && rect) {
              const side = sub.dataset['side'] as Side | undefined
              const right = side === 'right'
              const bleed = right ? -5 : 5
              const near = rect[right ? 'left' : 'right']
              const far = rect[right ? 'right' : 'left']
              content?.setGraceIntent(
                {
                  area: [
                    // A little back towards the trigger, so the exit point is inside the area.
                    { x: event.clientX + bleed, y: event.clientY },
                    { x: near, y: rect.top },
                    { x: far, y: rect.top },
                    { x: far, y: rect.bottom },
                    { x: near, y: rect.bottom },
                  ],
                  side,
                },
                300,
              )
            } else {
              if (content?.onTriggerLeave(event)) return
              content?.setGraceIntent(null)
            }
            hover.pointerleave?.(event)
          },
          keydown: event => {
            const trigger = event.currentTarget as HTMLElement
            if (disabled) return
            if (contentOf(trigger)?.isTypingAhead && event.key === ' ') return
            const dir = getDirection(trigger, this.root.explicitDir)
            if (!SUB_OPEN_KEYS[dir].includes(event.key)) return
            this.setOpen(true)
            this.contentRef.current?.focus()
            event.preventDefault()
          },
        },
        element: element => {
          this.triggerRef.set(element)
          const restoreId = ensureId(element, idFor(this, 'trigger'))
          queueMicrotask(() => {
            const level = contentOf(element)?.level
            if (level && level !== this.parent) this.parent = level
          })
          return () => {
            restoreId()
            this.triggerRef.release(element)
          }
        },
      }
    }),
  )

  <template>
    {{yield
      (hash
        Trigger=(component MenuSubTrigger part=this.trigger)
        Content=(component MenuSubContent sub=this)
        trigger=this.trigger
        isOpen=this.isOpen
        setOpen=this.setOpen
      )
    }}
  </template>
}

// ----- The root content -----------------------------------------------------------------------

/** What a menu's content takes: where it goes (Radix's Popper arguments) and what it does. */
export interface MenuContentArgs extends PopperContentArgs {
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Keep it rendered while closed, for animating it yourself. */
  forceMount?: boolean
  /** Whether the arrow keys go round from the last item to the first. Default `false`. */
  loop?: boolean
  /**
   * Called when it has closed, before focus goes back. `preventDefault()` to send focus
   * somewhere else.
   */
  onCloseAutoFocus?: (event: Event) => void
  /** Escape was pressed. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside it. `preventDefault()` keeps it open. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
  /** Focus moved outside it. `preventDefault()` keeps it open. */
  onFocusOutside?: (event: FocusOutsideEvent) => void
  /** Either of the last two, after its own handler. `preventDefault()` keeps it open. */
  onInteractOutside?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void
}

/** What a root does for its content, which differs between a dropdown and a context menu. */
export interface MenuContentHost extends MenuRoot {
  /** What the content is placed against: the trigger, or a context menu's point. */
  readonly reference: Element | VirtualElement | null
  /** The elements that count as inside the content, such as the trigger. */
  readonly inside: Array<Element | null>
  /** The content's id. */
  readonly contentId: string
  /** What names the content (its `aria-labelledby`), if anything. */
  readonly labelledBy: string | undefined
  /** The arrow the content places on its edge. */
  readonly arrowRef: ElementRef
  /** Its anchor options before the content's own and the defaults: the root's positioning. */
  readonly positioning: PopperContentArgs
  /** The defaults under the content's own arguments; `force` wins over them. */
  readonly contentDefaults: PopperContentArgs
  readonly contentForced: PopperContentArgs
  /** Closes the menu from the dismiss stack. */
  dismiss(reason: DismissReason): void
  /** Decides where focus goes when the content has closed. */
  closeAutoFocus(event: Event, handler?: (event: Event) => void): void
  /** Notes a press or focus outside, for `closeAutoFocus`. */
  interactOutside(
    event: PointerDownOutsideEvent | FocusOutsideEvent,
    handler?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void,
  ): void
}

/** What a menu's content yields, as ember-primitives' Menu's Content does. */
export interface MenuContentBlockParams {
  Item: WithBoundArgs<typeof MenuItem, 'part'>
  LinkItem: WithBoundArgs<typeof MenuLinkItem, 'part'>
  Separator: WithBoundArgs<typeof MenuSeparator, 'part'>
}

export interface MenuContentSignature {
  Args: MenuContentArgs & {
    /** @internal The root, bound by it. */
    menu: MenuContentHost
    /** @internal The item modifier, for the yielded Item. */
    itemPart: PartModifier<HTMLElement, MenuItemOptions>
  }
  Blocks: { default: [MenuContentBlockParams] }
  Element: HTMLDivElement
}

/**
 * A menu's content, as Radix's `MenuContent`: a `role="menu"` in the top layer while open,
 * placed against its trigger, with focus moving in (to the first item, when the keyboard
 * opened it), the arrow keys and typeahead between its items, Escape or a press outside closing
 * it, and focus going back when it closes. A modal menu (the default) keeps focus inside, the
 * pointer off the rest of the page, makes it inert and stops it scrolling.
 */
export class MenuContent extends Component<MenuContentSignature> {
  get menu(): MenuContentHost {
    return this.args.menu
  }

  get anchorOptions(): AnchorOptions {
    const { menu } = this
    const options = popperOptions(this.args, menu.positioning, menu.contentDefaults, {
      arrow: menu.arrowRef.value,
    })
    return { ...options, ...menu.contentForced } as AnchorOptions
  }

  /** While a modal menu is open, the rest of the page is out of reach. */
  get isModalOpen(): boolean {
    return this.menu.isModal && this.menu.isOpen
  }

  /** Focus is taken in and kept while it is shown; a force-mounted content that is closed is left alone. */
  get scopesFocus(): boolean {
    return this.menu.isOpen || !this.args.forceMount
  }

  contentPart = part<HTMLElement>(() => {
    const { menu } = this
    return {
      attributes: {
        id: menu.contentId,
        role: 'menu',
        'aria-orientation': 'vertical',
        'aria-labelledby': menu.labelledBy,
        'data-state': menu.isOpen ? 'open' : 'closed',
        dir: menu.explicitDir,
        tabindex: '-1',
        'data-test-jn-part': 'content',
        'data-test-jn-owner': menu.id,
      },
      element: element => {
        const restore = exposeProperties(element, menu.cssName)
        const state = new MenuContentState(element, menu, menu, {
          loop: () => this.args.loop ?? false,
        })
        const uninstall = state.install()
        return () => {
          uninstall()
          restore()
        }
      },
    }
  })

  /** Focus goes to the content itself, and on to the first item when the keyboard is in use. */
  onOpenAutoFocus = (event: Event): void => {
    event.preventDefault()
    const content = event.target as HTMLElement
    content.focus({ preventScroll: true })
  }

  onCloseAutoFocus = (event: Event): void =>
    this.menu.closeAutoFocus(event, this.args.onCloseAutoFocus)

  onEscapeKeyDown = (event: KeyboardEvent): void => this.args.onEscapeKeyDown?.(event)

  onFocusOutside = (event: FocusOutsideEvent): void => {
    this.args.onFocusOutside?.(event)
    // Focus stays inside a modal menu, so focus outside never closes one.
    if (this.menu.isModal) event.preventDefault()
  }

  onInteractOutside = (event: PointerDownOutsideEvent | FocusOutsideEvent): void =>
    this.menu.interactOutside(event, this.args.onInteractOutside)

  <template>
    <Presence @present={{this.menu.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{presence.ref}}
        {{this.contentPart}}
        {{topLayer}}
        {{anchorMenu this.menu.reference this.anchorOptions}}
        {{dismissable
          enabled=this.menu.isOpen
          onDismiss=this.menu.dismiss
          onEscapeKeyDown=this.onEscapeKeyDown
          onPointerDownOutside=@onPointerDownOutside
          onFocusOutside=this.onFocusOutside
          onInteractOutside=this.onInteractOutside
          disableOutsidePointerEvents=this.isModalOpen
          inside=this.menu.inside
        }}
        {{MenuFocus
          enabled=this.scopesFocus
          trapped=this.isModalOpen
          onMountAutoFocus=this.onOpenAutoFocus
          onUnmountAutoFocus=this.onCloseAutoFocus
        }}
        {{InertOutside enabled=this.isModalOpen}}
        {{scrollLock enabled=this.isModalOpen}}
      >{{yield
          (hash
            Item=(component MenuItem part=@itemPart)
            LinkItem=(component MenuLinkItem part=@itemPart)
            Separator=(component MenuSeparator part=separatorPart)
          )
        }}</As>
    </Presence>
  </template>
}
