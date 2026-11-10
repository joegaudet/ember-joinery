import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { modifier as functionModifier } from 'ember-modifier'
import { As, type TagName } from './as.gts'
import { controllable, type ControllableArgs } from './controllable-state.ts'
import { getDirection, type Direction } from './direction.gts'
import { dismissable, type FocusOutsideEvent, type PointerDownOutsideEvent } from './dismiss.ts'
import { idFor } from './id.ts'
import { part, type PartModifier, type PartSpec } from './part.ts'
import { Presence } from './presence.gts'
import { ignoreROError } from './resize-observer.ts'
import { visuallyHidden } from './visually-hidden.gts'
import { Delay, ElementRef, buttonType } from './-private/popper.gts'

/** Which way the list runs: its triggers and links side by side, or one above another. */
export type NavigationMenuOrientation = 'horizontal' | 'vertical'

/** What a `<NavigationMenu>` takes. */
export type NavigationMenuArgs = ControllableArgs<'value', string> & {
  /**
   * How long the pointer rests on a trigger before its content opens, in milliseconds. Default
   * 200, as Radix's.
   */
  delayDuration?: number
  /**
   * How long after the pointer leaves that moving onto another trigger opens it at once, without
   * the delay, in milliseconds. Default 300.
   */
  skipDelayDuration?: number
  /** Which way the list runs. Default `horizontal`. */
  orientation?: NavigationMenuOrientation
  /** The text direction, when the document's (at the menu) shouldn't decide. */
  dir?: Direction
  /** Its name, for `NavigationMenuHarness` (`data-test-jn-name`). */
  name?: string
  /** The tag to render. Default `nav`. */
  as?: TagName
}

/** Sent up from a link that is selected, or a content that is dismissed: the content closes. */
const ROOT_CONTENT_DISMISS = 'navigationMenu.rootContentDismiss'
/** Sent to a link when it is selected; cancel it (`@onSelect`) to keep the content open. */
const LINK_SELECT = 'navigationMenu.linkSelect'

const ARROW_KEYS = ['ArrowRight', 'ArrowLeft', 'ArrowUp', 'ArrowDown']

function isMouse(event: PointerEvent): boolean {
  return event.pointerType === 'mouse'
}

/** The elements a Tab can land on inside `container`, in order, as Radix's navigation menu finds them. */
function tabbableCandidates(container: HTMLElement): HTMLElement[] {
  const nodes: HTMLElement[] = []
  const walker = document.createTreeWalker(container, NodeFilter.SHOW_ELEMENT, {
    acceptNode: node => {
      const element = node as HTMLElement & { disabled?: boolean; type?: string }
      const isHiddenInput = element.tagName === 'INPUT' && element.type === 'hidden'
      if (element.disabled || element.hidden || isHiddenInput) return NodeFilter.FILTER_SKIP
      return element.tabIndex >= 0 ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP
    },
  })
  while (walker.nextNode()) nodes.push(walker.currentNode as HTMLElement)
  return nodes
}

/** Radix's `focusFirst` here: true when focus moved, or was already on a candidate. */
function focusFirst(candidates: Array<HTMLElement | null | undefined>): boolean {
  const previous = document.activeElement
  return candidates.some(candidate => {
    if (!candidate) return false
    if (candidate === previous) return true
    candidate.focus()
    return document.activeElement !== previous
  })
}

/** Takes elements out of the tab order; returns what puts them back. */
function removeFromTabOrder(candidates: HTMLElement[]): () => void {
  const previous = candidates.map(candidate => candidate.getAttribute('tabindex'))
  for (const candidate of candidates) candidate.setAttribute('tabindex', '-1')
  return () => {
    candidates.forEach((candidate, index) => {
      const tabindex = previous[index]
      if (tabindex === null || tabindex === undefined) candidate.removeAttribute('tabindex')
      else candidate.setAttribute('tabindex', tabindex)
    })
  }
}

/** Sorts elements' owners into document order. */
function inDocumentOrder<T>(entries: T[], element: (entry: T) => Element): T[] {
  return entries.sort((a, b) =>
    element(a).compareDocumentPosition(element(b)) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
  )
}

/**
 * A value that lasts from one read to the next, as a React ref does across renders: Radix's
 * `usePrevious`, and the motion and trigger its navigation menu keeps while nothing replaces
 * them. Reading it changes nothing a template tracks.
 */
class Remembered<T> {
  #value: T
  #previous: T

  constructor(value: T) {
    this.#value = value
    this.#previous = value
  }

  /** The value before `value`, the last time it changed. */
  previousOf(value: T): T {
    if (value !== this.#value) {
      this.#previous = this.#value
      this.#value = value
    }
    return this.#previous
  }

  /** `value`, kept, unless it is `undefined`: then the last one kept. */
  keep(value: T | undefined): T {
    if (value !== undefined) this.#value = value
    return this.#value
  }
}

// ----- Focus groups ---------------------------------------------------------------------------

/**
 * The list and each content are a focus group, as Radix's navigation menu's: the arrow keys,
 * Home and End move between the triggers and links in it (not round, and in both directions
 * whatever the orientation). The group of an item is the nearest group element above it.
 */
const focusGroups = new WeakSet<Element>()
const focusGroupItems = new WeakSet<Element>()

function groupOf(element: Element): Element | null {
  for (let parent = element.parentElement; parent; parent = parent.parentElement) {
    if (focusGroups.has(parent)) return parent
  }
  return null
}

function groupItems(group: Element): HTMLElement[] {
  return [...group.querySelectorAll<HTMLElement>('*')].filter(
    element => focusGroupItems.has(element) && groupOf(element) === group,
  )
}

/** A key on a trigger or a link: move focus between its group's items. */
function onFocusGroupKeyDown(event: KeyboardEvent, dir: Direction): void {
  if (event.defaultPrevented) return
  if (!['Home', 'End', ...ARROW_KEYS].includes(event.key)) return
  const item = event.currentTarget as HTMLElement
  const group = groupOf(item)
  if (!group) return
  let candidates = groupItems(group)
  const prevItemKey = dir === 'rtl' ? 'ArrowRight' : 'ArrowLeft'
  if ([prevItemKey, 'ArrowUp', 'End'].includes(event.key)) candidates.reverse()
  if (ARROW_KEYS.includes(event.key)) candidates = candidates.slice(candidates.indexOf(item) + 1)
  focusFirst(candidates)
  event.preventDefault()
}

/** Makes an element a focus group. */
const focusGroup = functionModifier((element: HTMLElement) => {
  focusGroups.add(element)
  return () => focusGroups.delete(element)
})

// ----- The root ---------------------------------------------------------------------------------

/**
 * A site's navigation, as Radix's `NavigationMenu` (which shadcn's is built on): a `<nav>` with
 * a list of links, some of them triggers that open a panel of more links. It yields its parts:
 *
 *   <NavigationMenu as |n|>
 *     <n.List>
 *       <n.Item as |item|>
 *         <item.Trigger>Getting started</item.Trigger>
 *         <item.Content>
 *           <n.Link href="/docs">Introduction</n.Link>
 *         </item.Content>
 *       </n.Item>
 *       <n.Item><n.Link href="/docs">Docs</n.Link></n.Item>
 *     </n.List>
 *     <n.Viewport />
 *   </NavigationMenu>
 *
 * A trigger opens its content on a click, or when the pointer rests on it (after
 * `@delayDuration`, and at once when another has just been open), and the content closes when
 * the pointer has left both for a moment. With a `Viewport`, every content shows in it, sized
 * to the one that is open and sliding in from the side of the trigger it replaces
 * (`data-motion`). Tab goes from a trigger into its open content and out again to the next
 * trigger; the arrow keys, Home and End move between the triggers and links; Escape closes it.
 * Which content is open is `@value` (its item's `@value`, or `''` for none), its own or yours
 * with `@onValueChange`.
 */
export class NavigationMenu extends Component<NavigationMenuSignature> {
  valueState = controllable(this, 'value', '')
  rootRef = new ElementRef()
  viewportRef = new ElementRef()
  trackRef = new ElementRef()
  readonly items = new Set<NavigationMenuItem>()
  /** Whether a Viewport is part of the menu, so its contents show there. */
  @tracked hasViewport = false
  #isOpenDelayed = true
  #openTimer = new Delay(this)
  #closeTimer = new Delay(this)
  #skipDelayTimer: ReturnType<typeof setTimeout> | undefined
  #previous = new Remembered('')
  #sizedContent: HTMLElement | undefined
  #sizeObserver: ResizeObserver | undefined

  constructor(owner: Owner, args: NavigationMenuSignature['Args']) {
    super(owner, args)
    registerDestructor(this, () => {
      clearTimeout(this.#skipDelayTimer)
      this.#sizeObserver?.disconnect()
    })
  }

  get id(): string {
    return idFor(this)
  }

  /** The open item's value, or `''`. */
  get value(): string {
    return this.valueState.value
  }

  /** The value before the last change, as Radix's `usePrevious`. */
  get previousValue(): string {
    return this.#previous.previousOf(this.value)
  }

  get isOpen(): boolean {
    return this.value !== ''
  }

  get orientation(): NavigationMenuOrientation {
    return this.args.orientation ?? 'horizontal'
  }

  get dir(): Direction {
    return getDirection(this.rootRef.current, this.args.dir)
  }

  /** The direction to render (`dir`): `@dir`, or nothing, so the document's applies. */
  get explicitDir(): Direction | undefined {
    return this.args.dir
  }

  /** Its items that have a trigger, in the triggers' order. */
  triggerItems(): NavigationMenuItem[] {
    const items = [...this.items].filter(item => item.triggerRef.current)
    return inDocumentOrder(items, item => item.triggerRef.current!)
  }

  /** Every trigger: a press there doesn't dismiss a content (the trigger itself toggles it). */
  isTrigger(target: Node): boolean {
    return this.triggerItems().some(item => item.triggerRef.current!.contains(target))
  }

  setValue = (value: string): void => {
    if (value !== this.value) {
      const skipDelayDuration = this.args.skipDelayDuration ?? 300
      clearTimeout(this.#skipDelayTimer)
      if (value !== '') {
        if (skipDelayDuration > 0) this.#isOpenDelayed = false
      } else {
        this.#skipDelayTimer = setTimeout(() => (this.#isOpenDelayed = true), skipDelayDuration)
      }
    }
    this.valueState.set(value)
  }

  #startCloseTimer(): void {
    this.#closeTimer.start(150, () => this.setValue(''))
  }

  #open(value: string): void {
    this.#closeTimer.cancel()
    this.setValue(value)
  }

  #delayedOpen(value: string): void {
    if (this.value === value) return this.#closeTimer.cancel()
    this.#openTimer.start(this.args.delayDuration ?? 200, () => {
      this.#closeTimer.cancel()
      this.setValue(value)
    })
  }

  onTriggerEnter(value: string): void {
    this.#openTimer.cancel()
    if (this.#isOpenDelayed) this.#delayedOpen(value)
    else this.#open(value)
  }

  onTriggerLeave(): void {
    this.#openTimer.cancel()
    this.#startCloseTimer()
  }

  onContentEnter = (): void => this.#closeTimer.cancel()

  onContentLeave = (event: PointerEvent): void => {
    if (isMouse(event)) this.#startCloseTimer()
  }

  /** A click on a trigger: opens its content, or closes it when it is open. */
  onItemSelect(value: string): void {
    this.setValue(this.value === value ? '' : value)
  }

  onItemDismiss(): void {
    this.setValue('')
  }

  /** Sizes the viewport to the content that is open, now and as it changes size. */
  sizeViewportTo(content: HTMLElement): void {
    const resize = () => {
      const viewport = this.viewportRef.current
      if (!viewport || !content.isConnected) return
      viewport.style.setProperty(
        '--radix-navigation-menu-viewport-width',
        `${content.offsetWidth}px`,
      )
      viewport.style.setProperty(
        '--radix-navigation-menu-viewport-height',
        `${content.offsetHeight}px`,
      )
    }
    resize()
    if (this.#sizedContent === content) return
    this.#sizedContent = content
    this.#sizeObserver?.disconnect()
    if (typeof ResizeObserver === 'undefined') return
    ignoreROError()
    this.#sizeObserver = new ResizeObserver(resize)
    this.#sizeObserver.observe(content)
  }

  /** The Viewport has rendered (or gone): its contents show there from now on. */
  registerViewport = (): (() => void) => {
    queueMicrotask(() => (this.hasViewport = true))
    return () => queueMicrotask(() => (this.hasViewport = false))
  }

  /** The link modifier, for the yielded Link and your own elements. */
  link: PartModifier<HTMLElement, NavigationMenuLinkOptions> = navigationMenuLinkPart(this)

  root = part<HTMLElement>(() => ({
    attributes: { 'data-orientation': this.orientation, dir: this.explicitDir },
    element: element => {
      this.rootRef.set(element)
      return () => this.rootRef.release(element)
    },
  }))

  <template>
    <As
      @as={{@as}}
      @tag="nav"
      id={{this.id}}
      aria-label="Main"
      data-test-jn="navigation-menu"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.root}}
    >{{yield
        (hash
          List=(component NavigationMenuList root=this)
          Item=(component NavigationMenuItem root=this)
          Link=(component NavigationMenuLink link=this.link)
          Indicator=(component NavigationMenuIndicator root=this)
          Viewport=(component NavigationMenuViewport root=this)
          link=this.link
          value=this.value
          isOpen=this.isOpen
          setValue=this.setValue
        )
      }}</As>
  </template>
}

// ----- The list ---------------------------------------------------------------------------------

interface ListSignature {
  Args: {
    /** @internal The menu, bound by it. */
    root: NavigationMenu
  }
  Blocks: { default: [] }
  Element: HTMLUListElement
}

const positionRelative = functionModifier((element: HTMLElement) => {
  element.style.setProperty('position', 'relative')
})

/**
 * The list of items: a `<ul>`, a focus group, in a `<div>` the Indicator is placed in (Radix's
 * indicator track).
 */
class NavigationMenuList extends Component<ListSignature> {
  track = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'indicator-track' },
    element: element => {
      this.args.root.trackRef.set(element)
      return () => this.args.root.trackRef.release(element)
    },
  }))

  <template>
    <div {{positionRelative}} {{this.track}}>
      <ul
        data-orientation={{@root.orientation}}
        dir={{@root.explicitDir}}
        data-test-jn-part="list"
        ...attributes
        {{focusGroup}}
      >{{yield}}</ul>
    </div>
  </template>
}

// ----- An item -----------------------------------------------------------------------------------

/** What a trigger and its modifier take. */
export interface NavigationMenuTriggerOptions {
  /** Whether it is disabled: it opens nothing, and the keys skip it. */
  disabled?: boolean
}

interface TriggerSignature {
  Args: NavigationMenuTriggerOptions & {
    /** @internal The item, bound by it. */
    item: NavigationMenuItem
    /** The tag to render. Default `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * A `<button>` that opens its item's content. While it is open, a focus proxy after it sends
 * Tab into the content, and (with a Viewport) an `aria-owns` puts the content after it for
 * assistive technology, wherever it is rendered.
 */
const NavigationMenuTrigger: TOC<TriggerSignature> = <template>
  <As
    @as={{@as}}
    @tag="button"
    disabled={{@disabled}}
    ...attributes
    {{@item.trigger disabled=@disabled}}
  >{{yield}}</As>
  {{#if @item.isOpen}}
    <span tabindex="0" data-test-jn-part="focus-proxy" {{visuallyHidden}} {{@item.focusProxy}} />
    {{#if @item.root.hasViewport}}
      <span aria-owns={{@item.contentId}} />
    {{/if}}
  {{/if}}
</template>

/** What a content takes. */
export interface NavigationMenuContentArgs {
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Keep it rendered while closed, for animating it yourself. */
  forceMount?: boolean
  /** Escape was pressed. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside it. `preventDefault()` keeps it open. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
  /** Focus moved outside it. `preventDefault()` keeps it open. */
  onFocusOutside?: (event: FocusOutsideEvent) => void
  /** Either of the last two. `preventDefault()` keeps it open. */
  onInteractOutside?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void
}

interface ContentSignature {
  Args: NavigationMenuContentArgs & {
    /** @internal The item, bound by it. */
    item: NavigationMenuItem
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * An item's content: in the Viewport when the menu has one (sliding in from the side of the
 * trigger it replaces, `data-motion`), and otherwise below its trigger, in its item.
 */
class NavigationMenuContent extends Component<ContentSignature> {
  #motion = new Remembered<string | null>(null)

  get item(): NavigationMenuItem {
    return this.args.item
  }

  get root(): NavigationMenu {
    return this.args.item.root
  }

  get viewport(): HTMLElement | null {
    return this.root.viewportRef.value
  }

  /** In the Viewport, the content shown is the open one, or the one closing with the menu. */
  get isActive(): boolean {
    const { root } = this
    const active = root.isOpen ? root.value : root.previousValue
    return active === this.item.value
  }

  /**
   * Which way it moves, as Radix's: `from-start` or `from-end` as it replaces the content of a
   * trigger before or after its own, and `to-start` or `to-end` as it gives way to one.
   */
  get motion(): string | null {
    const { root } = this
    const values = root.triggerItems().map(item => item.value)
    if (root.dir === 'rtl') values.reverse()
    const value = root.value
    const previousValue = root.previousValue
    const index = values.indexOf(value)
    const prevIndex = values.indexOf(previousValue)
    const isSelected = this.item.value === value
    const wasSelected = prevIndex === values.indexOf(this.item.value)
    if (!isSelected && !wasSelected) return this.#motion.keep(undefined)
    let attribute: string | null = null
    if (index !== prevIndex) {
      if (isSelected && prevIndex !== -1) attribute = index > prevIndex ? 'from-end' : 'from-start'
      else if (wasSelected && index !== -1) attribute = index > prevIndex ? 'to-start' : 'to-end'
    }
    return this.#motion.keep(attribute)
  }

  get isInViewport(): boolean {
    return this.root.hasViewport
  }

  content = part<HTMLElement, { inViewport: boolean }>(({ inViewport }) => {
    const { item, root } = this
    const open = item.isOpen
    const spec: PartSpec<HTMLElement> = {
      attributes: {
        id: item.contentId,
        'aria-labelledby': item.triggerId,
        'data-motion': this.motion,
        'data-orientation': root.orientation,
        'data-state': inViewport ? undefined : open ? 'open' : 'closed',
        dir: root.explicitDir,
        'data-test-jn-part': 'content',
        'data-test-jn-value': item.value,
      },
      on: {
        keydown: event => this.#onKeyDown(event),
        ...(inViewport
          ? {}
          : {
              pointerenter: () => root.onContentEnter(),
              pointerleave: (event: PointerEvent) => root.onContentLeave(event),
            }),
      },
      element: element => {
        focusGroups.add(element)
        item.contentRef.set(element)
        const onRootDismiss = () => {
          root.onItemDismiss()
          item.onRootContentClose()
          if (element.contains(document.activeElement)) item.triggerRef.current?.focus()
        }
        element.addEventListener(ROOT_CONTENT_DISMISS, onRootDismiss)
        return () => {
          element.removeEventListener(ROOT_CONTENT_DISMISS, onRootDismiss)
          focusGroups.delete(element)
          item.contentRef.release(element)
        }
      },
    }
    return spec
  })

  /** While it is closing in place, it takes no pointer: Radix's "prevent interaction when animating out". */
  pointerEvents = functionModifier((element: HTMLElement, [open]: [boolean]) => {
    if (open) element.style.removeProperty('pointer-events')
    else element.style.setProperty('pointer-events', 'none')
  })

  /** The Viewport sizes itself to the content that is shown in it. */
  sizeViewport = functionModifier((element: HTMLElement, [active]: [boolean]) => {
    if (active) this.root.sizeViewportTo(element)
  })

  /** Tab moves through its links, and from the last (or first) out through the focus proxy. */
  #onKeyDown(event: KeyboardEvent): void {
    const isMetaKey = event.altKey || event.ctrlKey || event.metaKey
    if (event.key !== 'Tab' || isMetaKey) return
    const candidates = tabbableCandidates(event.currentTarget as HTMLElement)
    const index = candidates.findIndex(candidate => candidate === document.activeElement)
    const next = event.shiftKey
      ? candidates.slice(0, index).reverse()
      : candidates.slice(index + 1, candidates.length)
    if (focusFirst(next)) event.preventDefault()
    else this.item.focusProxyRef.current?.focus()
  }

  onDismiss = (): void => {
    this.item.contentRef.current?.dispatchEvent(
      new Event(ROOT_CONTENT_DISMISS, { bubbles: true, cancelable: true }),
    )
  }

  onEscapeKeyDown = (event: KeyboardEvent): void => {
    this.args.onEscapeKeyDown?.(event)
    if (!event.defaultPrevented) this.item.wasEscapeClose = true
  }

  onFocusOutside = (event: FocusOutsideEvent): void => {
    this.args.onFocusOutside?.(event)
    if (event.defaultPrevented) return
    this.item.onContentFocusOutside()
    const target = event.target as Node | null
    const nav = this.root.rootRef.current
    if (target && nav?.contains(target)) event.preventDefault()
  }

  onPointerDownOutside = (event: PointerDownOutsideEvent): void => {
    this.args.onPointerDownOutside?.(event)
    if (event.defaultPrevented) return
    const target = event.target as Node | null
    if (!target) return
    const isTrigger = this.root.isTrigger(target)
    const isRootViewport = this.viewport?.contains(target) ?? false
    if (isTrigger || isRootViewport) event.preventDefault()
  }

  <template>
    {{#if this.isInViewport}}
      {{#if this.viewport}}
        {{#in-element this.viewport insertBefore=null}}
          <Presence @present={{this.isActive}} @forceMount={{@forceMount}} as |presence|>
            <As
              @as={{@as}}
              @tag="div"
              ...attributes
              {{presence.ref}}
              {{this.content inViewport=true}}
              {{this.sizeViewport this.isActive}}
              {{dismissable
                enabled=this.item.isOpen
                onDismiss=this.onDismiss
                onEscapeKeyDown=this.onEscapeKeyDown
                onPointerDownOutside=this.onPointerDownOutside
                onFocusOutside=this.onFocusOutside
                onInteractOutside=@onInteractOutside
              }}
            >{{yield}}</As>
          </Presence>
        {{/in-element}}
      {{/if}}
    {{else}}
      <Presence @present={{this.item.isOpen}} @forceMount={{@forceMount}} as |presence|>
        <As
          @as={{@as}}
          @tag="div"
          ...attributes
          {{presence.ref}}
          {{this.content inViewport=false}}
          {{this.pointerEvents this.item.isOpen}}
          {{dismissable
            enabled=this.item.isOpen
            onDismiss=this.onDismiss
            onEscapeKeyDown=this.onEscapeKeyDown
            onPointerDownOutside=this.onPointerDownOutside
            onFocusOutside=this.onFocusOutside
            onInteractOutside=@onInteractOutside
          }}
        >{{yield}}</As>
      </Presence>
    {{/if}}
  </template>
}

/** What an item yields: its trigger and content, the trigger's modifier, and its state. */
export interface NavigationMenuItemBlockParams {
  /** The `<button>` that opens its content. */
  Trigger: WithBoundArgs<typeof NavigationMenuTrigger, 'item'>
  /** Its content: the links it opens. */
  Content: WithBoundArgs<typeof NavigationMenuContent, 'item'>
  /** Makes your own element the trigger: `<button {{item.trigger}}>`. */
  trigger: PartModifier<HTMLElement, NavigationMenuTriggerOptions>
  /** Its value: the menu's `@value` while its content is open. */
  value: string
  /** Whether its content is open. */
  isOpen: boolean
}

export interface NavigationMenuItemSignature {
  Args: {
    /** @internal The menu, bound by it. */
    root: NavigationMenu
    /** Its value, for the menu's `@value`. Default: an id of its own. */
    value?: string
    /** The tag to render. Default `li`. */
    as?: TagName
  }
  Blocks: { default: [NavigationMenuItemBlockParams] }
  Element: HTMLLIElement
}

/** An item of the list: an `<li>` holding a link, or a trigger and its content. */
export class NavigationMenuItem extends Component<NavigationMenuItemSignature> {
  triggerRef = new ElementRef()
  contentRef = new ElementRef()
  focusProxyRef = new ElementRef()
  /** Escape closed it: the pointer resting on its trigger doesn't open it again until it leaves. */
  wasEscapeClose = false
  #wasClickClose = false
  #hasPointerMoveOpened = false
  #restoreContentTabOrder: () => void = () => {}

  constructor(owner: Owner, args: NavigationMenuItemSignature['Args']) {
    super(owner, args)
    this.root.items.add(this)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.root.items.delete(this)
  }

  get root(): NavigationMenu {
    return this.args.root
  }

  get value(): string {
    return this.args.value || idFor(this, 'item')
  }

  get isOpen(): boolean {
    return this.root.value === this.value
  }

  get triggerId(): string {
    return `${this.root.id}-trigger-${this.value}`
  }

  get contentId(): string {
    return `${this.root.id}-content-${this.value}`
  }

  /** Focus into the content: its first link (`start`) or its last (`end`). */
  onContentEntry = (side: 'start' | 'end' = 'start'): void => {
    const content = this.contentRef.current
    if (!content) return
    this.#restoreContentTabOrder()
    const candidates = tabbableCandidates(content)
    if (candidates.length) focusFirst(side === 'start' ? candidates : candidates.reverse())
  }

  /** Focus left the content, or it closed: its links leave the tab order until focus comes back. */
  #onContentExit(): void {
    const content = this.contentRef.current
    if (!content) return
    const candidates = tabbableCandidates(content)
    if (candidates.length) this.#restoreContentTabOrder = removeFromTabOrder(candidates)
  }

  onRootContentClose(): void {
    this.#onContentExit()
  }

  onContentFocusOutside(): void {
    this.#onContentExit()
  }

  trigger: PartModifier<HTMLElement, NavigationMenuTriggerOptions> = part<
    HTMLElement,
    NavigationMenuTriggerOptions
  >(options => {
    const disabled = options.disabled ?? false
    const { root } = this
    const open = this.isOpen
    return {
      attributes: {
        id: this.triggerId,
        'data-disabled': disabled ? '' : undefined,
        'data-state': open ? 'open' : 'closed',
        'aria-expanded': String(open),
        'aria-controls': this.contentId,
        'data-test-jn-part': 'trigger',
        'data-test-jn-value': this.value,
      },
      on: {
        pointerenter: () => {
          this.#wasClickClose = false
          this.wasEscapeClose = false
        },
        pointermove: event => {
          if (!isMouse(event)) return
          if (disabled || this.#wasClickClose || this.wasEscapeClose) return
          if (this.#hasPointerMoveOpened) return
          root.onTriggerEnter(this.value)
          this.#hasPointerMoveOpened = true
        },
        pointerleave: event => {
          if (!isMouse(event) || disabled) return
          root.onTriggerLeave()
          this.#hasPointerMoveOpened = false
        },
        click: () => {
          const wasOpen = this.isOpen
          root.onItemSelect(this.value)
          this.#wasClickClose = wasOpen
        },
        keydown: event => {
          const verticalEntryKey = root.dir === 'rtl' ? 'ArrowLeft' : 'ArrowRight'
          const entryKey = root.orientation === 'horizontal' ? 'ArrowDown' : verticalEntryKey
          if (this.isOpen && event.key === entryKey) {
            this.onContentEntry()
            event.preventDefault()
          }
          onFocusGroupKeyDown(event, root.dir)
        },
      },
      element: element => {
        this.triggerRef.set(element)
        focusGroupItems.add(element)
        const restoreType = buttonType(element)
        return () => {
          restoreType()
          focusGroupItems.delete(element)
          this.triggerRef.release(element)
        }
      },
    }
  })

  /** The focus proxy after an open trigger: Tab onto it goes into the content. */
  focusProxy = part<HTMLElement>(() => ({
    attributes: {},
    on: {
      focus: event => {
        const content = this.contentRef.current
        const previous = event.relatedTarget as Node | null
        const wasTriggerFocused = previous === this.triggerRef.current
        const wasFocusFromContent = previous ? (content?.contains(previous) ?? false) : false
        if (wasTriggerFocused || !wasFocusFromContent) {
          this.onContentEntry(wasTriggerFocused ? 'start' : 'end')
        }
      },
    },
    element: element => {
      this.focusProxyRef.set(element)
      return () => this.focusProxyRef.release(element)
    },
  }))

  <template>
    <As
      @as={{@as}}
      @tag="li"
      data-test-jn-part="item"
      data-test-jn-value={{this.value}}
      ...attributes
    >
      {{yield
        (hash
          Trigger=(component NavigationMenuTrigger item=this)
          Content=(component NavigationMenuContent item=this)
          trigger=this.trigger
          value=this.value
          isOpen=this.isOpen
        )
      }}
    </As>
  </template>
}

// ----- A link ------------------------------------------------------------------------------------

/** What a link and its modifier take. */
export interface NavigationMenuLinkOptions {
  /** Whether it is the current page: `data-active` and `aria-current="page"`. */
  active?: boolean
  /**
   * Called when it is selected (a click or Enter), with a cancelable event:
   * `event.preventDefault()` keeps the content it is in open.
   */
  onSelect?: (event: Event) => void
}

/** A link's modifier: Radix's NavigationMenuLink on your own element (`<LinkTo {{n.link}}>`). */
export function navigationMenuLinkPart(
  root: NavigationMenu,
): PartModifier<HTMLElement, NavigationMenuLinkOptions> {
  return part<HTMLElement, NavigationMenuLinkOptions>(options => ({
    attributes: {
      'data-active': options.active ? '' : undefined,
      'aria-current': options.active ? 'page' : undefined,
      'data-test-jn-part': 'link',
    },
    on: {
      keydown: event => onFocusGroupKeyDown(event, root.dir),
      click: event => {
        const target = event.target as HTMLElement
        const select = new CustomEvent(LINK_SELECT, { bubbles: true, cancelable: true })
        target.addEventListener(LINK_SELECT, selected => options.onSelect?.(selected), {
          once: true,
        })
        target.dispatchEvent(select)
        if (!select.defaultPrevented && !event.metaKey) {
          target.dispatchEvent(
            new CustomEvent(ROOT_CONTENT_DISMISS, { bubbles: true, cancelable: true }),
          )
        }
      },
    },
    element: element => {
      focusGroupItems.add(element)
      return () => focusGroupItems.delete(element)
    },
  }))
}

interface LinkSignature {
  Args: NavigationMenuLinkOptions & {
    /** @internal The menu's link modifier, bound by it. */
    link: PartModifier<HTMLElement, NavigationMenuLinkOptions>
    /** The tag to render. Default `a`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLAnchorElement
}

/**
 * A link: an `<a>` (give it `href`), in the list or in a content. Selecting it closes the
 * content it is in, unless its `@onSelect` prevents that.
 */
const NavigationMenuLink: TOC<LinkSignature> = <template>
  <As @as={{@as}} @tag="a" ...attributes {{@link active=@active onSelect=@onSelect}}>{{yield}}</As>
</template>

// ----- The indicator ------------------------------------------------------------------------------

interface IndicatorSignature {
  Args: {
    /** @internal The menu, bound by it. */
    root: NavigationMenu
    /** Keep it rendered while nothing is open, for animating it yourself. */
    forceMount?: boolean
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * A mark under the open trigger, as Radix's `Indicator`: rendered in the list's track, as wide
 * as the trigger and moved along to it, `data-state="visible"` while a content is open.
 */
class NavigationMenuIndicator extends Component<IndicatorSignature> {
  #trigger = new Remembered<HTMLElement | null>(null)

  get root(): NavigationMenu {
    return this.args.root
  }

  get isVisible(): boolean {
    return this.root.isOpen
  }

  /** The trigger whose content is open, or the last one that was. */
  get activeTrigger(): HTMLElement | null {
    const value = this.root.value
    const item = this.root.triggerItems().find(each => each.value === value)
    return this.#trigger.keep(item?.triggerRef.current ?? undefined)
  }

  place = functionModifier(
    (
      element: HTMLElement,
      [trigger, track, orientation]: [HTMLElement | null, HTMLElement | null, string],
    ) => {
      const horizontal = orientation === 'horizontal'
      const position = () => {
        if (!trigger) return
        const size = horizontal ? trigger.offsetWidth : trigger.offsetHeight
        const offset = horizontal ? trigger.offsetLeft : trigger.offsetTop
        const style = element.style
        style.setProperty('position', 'absolute')
        if (horizontal) {
          style.setProperty('left', '0px')
          style.setProperty('width', `${size}px`)
          style.setProperty('transform', `translateX(${offset}px)`)
        } else {
          style.setProperty('top', '0px')
          style.setProperty('height', `${size}px`)
          style.setProperty('transform', `translateY(${offset}px)`)
        }
      }
      position()
      if (typeof ResizeObserver === 'undefined') return
      ignoreROError()
      const observer = new ResizeObserver(position)
      if (trigger) observer.observe(trigger)
      if (track) observer.observe(track)
      return () => observer.disconnect()
    },
  )

  <template>
    {{#if this.root.trackRef.value}}
      {{#in-element this.root.trackRef.value insertBefore=null}}
        <Presence @present={{this.isVisible}} @forceMount={{@forceMount}} as |presence|>
          <div
            aria-hidden="true"
            data-state={{if this.isVisible "visible" "hidden"}}
            data-orientation={{this.root.orientation}}
            data-test-jn-part="indicator"
            ...attributes
            {{presence.ref}}
            {{this.place this.activeTrigger this.root.trackRef.value this.root.orientation}}
          >{{yield}}</div>
        </Presence>
      {{/in-element}}
    {{/if}}
  </template>
}

// ----- The viewport ---------------------------------------------------------------------------------

interface ViewportSignature {
  Args: {
    /** @internal The menu, bound by it. */
    root: NavigationMenu
    /** Keep it rendered while nothing is open, for animating it yourself. */
    forceMount?: boolean
  }
  Element: HTMLDivElement
}

/**
 * Where every content shows, as Radix's `Viewport`: one panel, rendered while a content is open,
 * sized to it (`--radix-navigation-menu-viewport-width` and `-height`), so it can animate its
 * size as one content gives way to another.
 */
class NavigationMenuViewport extends Component<ViewportSignature> {
  constructor(owner: Owner, args: ViewportSignature['Args']) {
    super(owner, args)
    registerDestructor(this, args.root.registerViewport())
  }

  get root(): NavigationMenu {
    return this.args.root
  }

  viewport = part<HTMLElement>(() => {
    const { root } = this
    return {
      attributes: {
        'data-state': root.isOpen ? 'open' : 'closed',
        'data-orientation': root.orientation,
        'data-test-jn-part': 'viewport',
      },
      on: {
        pointerenter: () => root.onContentEnter(),
        pointerleave: event => root.onContentLeave(event),
      },
      element: element => {
        root.viewportRef.set(element)
        return () => root.viewportRef.release(element)
      },
    }
  })

  pointerEvents = functionModifier((element: HTMLElement, [open]: [boolean]) => {
    if (open) element.style.removeProperty('pointer-events')
    else element.style.setProperty('pointer-events', 'none')
  })

  <template>
    <Presence @present={{this.root.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <div
        ...attributes
        {{presence.ref}}
        {{this.viewport}}
        {{this.pointerEvents this.root.isOpen}}
      ></div>
    </Presence>
  </template>
}

/** What a `<NavigationMenu>` yields: its parts, the link modifier, and its state. */
export interface NavigationMenuBlockParams {
  /** The list of items. */
  List: WithBoundArgs<typeof NavigationMenuList, 'root'>
  /** An item: it yields its Trigger and Content, or holds a Link. */
  Item: WithBoundArgs<typeof NavigationMenuItem, 'root'>
  /** A link (give it `href`). */
  Link: WithBoundArgs<typeof NavigationMenuLink, 'link'>
  /** A mark under the open trigger. */
  Indicator: WithBoundArgs<typeof NavigationMenuIndicator, 'root'>
  /** Where every content shows, sized to the open one. */
  Viewport: WithBoundArgs<typeof NavigationMenuViewport, 'root'>
  /** Makes your own element a link: `<LinkTo @route="docs" {{n.link}}>`. */
  link: PartModifier<HTMLElement, NavigationMenuLinkOptions>
  /** The open item's value, or `''`. */
  value: string
  /** Whether a content is open. */
  isOpen: boolean
  /** Opens the content of the item with this value, or closes it (`''`). */
  setValue: (value: string) => void
}

export interface NavigationMenuSignature {
  Args: NavigationMenuArgs
  Blocks: { default: [NavigationMenuBlockParams] }
  Element: HTMLElement
}

export default NavigationMenu
