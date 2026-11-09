/* global HTMLElementTagNameMap -- a DOM type, which ESLint's browser globals don't list */
import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import Modifier from 'ember-modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { ControllableState } from './controllable-state.ts'
import { getDirection, type Direction } from './direction.gts'
import { focusFirst } from './focus.ts'
import { idFor } from './id.ts'

/** The event a group sends itself before it moves focus to an item, when Tab enters it. */
export const ENTRY_FOCUS = 'rovingFocusGroup.onEntryFocus'

/** The arrow keys a group listens to: left and right, up and down, or (unset) all four. */
export type Orientation = 'horizontal' | 'vertical'

/** Where a key asks focus to go. */
export type FocusIntent = 'first' | 'last' | 'prev' | 'next'

const KEY_TO_INTENT: Record<string, FocusIntent> = {
  ArrowLeft: 'prev',
  ArrowUp: 'prev',
  ArrowRight: 'next',
  ArrowDown: 'next',
  PageUp: 'first',
  Home: 'first',
  PageDown: 'last',
  End: 'last',
}

/** The key as it means in this direction: right to left, the left arrow moves forward. */
function directionAwareKey(key: string, dir: Direction): string {
  if (dir !== 'rtl') return key
  if (key === 'ArrowLeft') return 'ArrowRight'
  if (key === 'ArrowRight') return 'ArrowLeft'
  return key
}

/**
 * Where a key press asks focus to go in a group, as Radix's roving focus reads it: the arrows
 * along the orientation (both pairs when it is unset) move to the previous or next item, with
 * left and right swapped right to left; Home and PageUp go to the first, End and PageDown to
 * the last. Anything else is `undefined`.
 *
 *   getFocusIntent(event, 'horizontal', 'rtl') // 'next' for ArrowLeft
 */
export function getFocusIntent(
  event: Pick<KeyboardEvent, 'key'>,
  orientation: Orientation | undefined,
  dir: Direction,
): FocusIntent | undefined {
  const key = directionAwareKey(event.key, dir)
  if (orientation === 'vertical' && (key === 'ArrowLeft' || key === 'ArrowRight')) return undefined
  if (orientation === 'horizontal' && (key === 'ArrowUp' || key === 'ArrowDown')) return undefined
  return KEY_TO_INTENT[key]
}

/** The array, starting at `start` and wrapping round. */
function wrap<T>(array: T[], start: number): T[] {
  return array.map((_, index) => array[(start + index) % array.length]!)
}

/** Where a `RovingFocus` reads its settings. Each is a function, so it reads them live. */
export interface RovingFocusOptions {
  /** Which arrow keys move focus. Unset: all four. */
  orientation?: () => Orientation | undefined
  /** The text direction, when the DOM's (`getDirection`) shouldn't decide. */
  dir?: () => Direction | undefined
  /** Whether the arrows wrap round from the last item to the first and back. Default `false`. */
  loop?: () => boolean | undefined
  /** The controlled tab stop: the id of the item Tab enters on. */
  currentTabStopId?: () => string | null | undefined
  /** The first tab stop, when uncontrolled. */
  defaultCurrentTabStopId?: () => string | undefined
  /** Called with each new tab stop. */
  onCurrentTabStopIdChange?: () => ((id: string | null) => void) | undefined
  /** Called before Tab moves focus into an item; `event.preventDefault()` keeps it on the group. */
  onEntryFocus?: () => ((event: Event) => void) | undefined
  /** Don't scroll the item focused on entry into view. */
  preventScrollOnEntryFocus?: () => boolean | undefined
}

/** An item, as its group sees it. */
export interface RovingFocusItemState {
  /** Its element. */
  element: HTMLElement
  /** Its tab stop id. */
  id: string
  /** Whether focus can land on it. */
  focusable: boolean
  /** Whether Tab enters the group on it first. */
  active: boolean
}

export interface RovingFocusGroupModifierSignature {
  Element: HTMLElement
}

export interface RovingFocusItemModifierSignature {
  Element: HTMLElement
  Args: {
    Named: {
      /** The item's id, for the tab stop. Default: one of its own. */
      tabStopId?: string
      /** Whether focus can land on it. Default `true`; a disabled item passes `false`. */
      focusable?: boolean
      /** Whether Tab should enter on it first, as on a selected tab. Default `false`. */
      active?: boolean
    }
  }
}

/** Sets an attribute, or removes it for `null`. */
function write(element: Element, name: string, value: string | null): void {
  if (value === null) element.removeAttribute(name)
  else if (element.getAttribute(name) !== value) element.setAttribute(name, value)
}

/**
 * A roving tabindex, as Radix's `RovingFocusGroup`: the items of a group take one tab stop
 * between them, and the arrow keys move focus from item to item (APG's roving tabindex, and
 * tabster's Mover in ember-primitives). It remembers the item last focused, so Tab comes back
 * to it; enters on the `active` item first (a selected tab); flips left and right in
 * right-to-left text; and Shift+Tab leaves the group in one step.
 *
 * A component makes one and puts its two modifiers on its own elements, beside its own parts:
 *
 *   class Toolbar extends Component {
 *     roving = new RovingFocus({
 *       orientation: () => this.args.orientation ?? 'horizontal',
 *       loop: () => true,
 *     })
 *     <template>
 *       <div role="toolbar" {{this.roving.group}}>
 *         <button type="button" {{this.roving.item tabStopId="bold"}}>Bold</button>
 *         <button type="button" {{this.roving.item tabStopId="italic" focusable=false}}>Italic</button>
 *       </div>
 *     </template>
 *   }
 *
 * `<RovingFocusGroup>` is the same thing as a component, for an app's own groups.
 */
export class RovingFocus {
  readonly #options: RovingFocusOptions
  /** The tab stop: the id of the item that is in the tab order. */
  readonly tabStop: ControllableState<string | null>
  readonly #items = new Set<RovingFocusItemState>()
  #group: HTMLElement | undefined
  #isTabbingBackOut = false
  #isClickFocus = false

  /** Put it on the group's element. */
  readonly group: typeof Modifier<RovingFocusGroupModifierSignature>
  /** Put it on each item's element. */
  readonly item: typeof Modifier<RovingFocusItemModifierSignature>

  constructor(options: RovingFocusOptions = {}) {
    this.#options = options
    this.tabStop = new ControllableState<string | null>({
      name: 'currentTabStopId',
      value: () => options.currentTabStopId?.(),
      defaultValue: () => options.defaultCurrentTabStopId?.(),
      onChange: () => options.onCurrentTabStopIdChange?.(),
      fallback: null,
    })
    this.group = groupModifier(this)
    this.item = itemModifier(this)
  }

  /** The id of the item Tab enters on, or `null` when none has been focused yet. */
  get currentTabStopId(): string | null {
    return this.tabStop.value
  }

  get orientation(): Orientation | undefined {
    return this.#options.orientation?.()
  }

  /** The direction the arrow keys follow: the option, or the document's at the group. */
  get dir(): Direction {
    return getDirection(this.#group, this.#options.dir?.())
  }

  /** The items, in document order. */
  items(): RovingFocusItemState[] {
    return [...this.#items].sort((a, b) =>
      a.element.compareDocumentPosition(b.element) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
    )
  }

  // ----- The group -------------------------------------------------------------------------

  /** @internal */
  installGroup(element: HTMLElement): () => void {
    this.#group = element
    const outline = element.style.getPropertyValue('outline')
    // The group takes focus for a moment on the way to an item; Radix hides its outline.
    element.style.setProperty('outline', 'none')
    const onMouseDown = () => (this.#isClickFocus = true)
    const onFocusIn = (event: FocusEvent) => this.#onGroupFocus(event, element)
    const onFocusOut = () => {
      this.#isTabbingBackOut = false
      this.#syncGroup()
    }
    const onEntryFocus = (event: Event) => this.#options.onEntryFocus?.()?.(event)
    element.addEventListener('mousedown', onMouseDown)
    element.addEventListener('focusin', onFocusIn)
    element.addEventListener('focusout', onFocusOut)
    element.addEventListener(ENTRY_FOCUS, onEntryFocus)
    this.#syncGroup()
    return () => {
      element.removeEventListener('mousedown', onMouseDown)
      element.removeEventListener('focusin', onFocusIn)
      element.removeEventListener('focusout', onFocusOut)
      element.removeEventListener(ENTRY_FOCUS, onEntryFocus)
      if (outline) element.style.setProperty('outline', outline)
      else element.style.removeProperty('outline')
      if (this.#group === element) this.#group = undefined
    }
  }

  /** @internal Keeps the group's `data-orientation` current. */
  updateGroup(element: HTMLElement): void {
    write(element, 'data-orientation', this.orientation ?? null)
  }

  /**
   * The group is in the tab order while an item can take focus and Shift+Tab isn't leaving: Tab
   * lands on the group, which sends focus on to an item. It is set straight on the element, not
   * through tracked state, so it holds before the browser moves focus for the same key press.
   */
  #syncGroup(): void {
    const group = this.#group
    if (!group) return
    const focusable = [...this.#items].some(item => item.focusable)
    group.setAttribute('tabindex', this.#isTabbingBackOut || !focusable ? '-1' : '0')
  }

  /** Tab onto the group itself: send focus on to the active item, the tab stop, or the first. */
  #onGroupFocus(event: FocusEvent, group: HTMLElement): void {
    const isKeyboardFocus = !this.#isClickFocus
    if (event.target === group && isKeyboardFocus && !this.#isTabbingBackOut) {
      const entry = new CustomEvent(ENTRY_FOCUS, { bubbles: false, cancelable: true })
      group.dispatchEvent(entry)
      if (!entry.defaultPrevented) {
        const items = this.items().filter(item => item.focusable)
        const active = items.find(item => item.active)
        const current = items.find(item => item.id === this.currentTabStopId)
        const candidates = [active, current, ...items].filter(
          (item): item is RovingFocusItemState => !!item,
        )
        focusFirst(
          candidates.map(item => item.element),
          { preventScroll: this.#options.preventScrollOnEntryFocus?.() ?? false },
        )
      }
    }
    this.#isClickFocus = false
  }

  // ----- The items -------------------------------------------------------------------------

  /** @internal */
  register(item: RovingFocusItemState): () => void {
    this.#items.add(item)
    this.#syncGroup()
    return () => {
      this.#items.delete(item)
      this.#syncGroup()
    }
  }

  /** @internal An item's `focusable` changed. */
  changed(): void {
    this.#syncGroup()
  }

  /** @internal */
  onItemFocus(id: string): void {
    this.tabStop.set(id)
  }

  /** @internal */
  onItemMouseDown(event: MouseEvent, item: RovingFocusItemState): void {
    // A disabled item can't take focus from a click either.
    if (!item.focusable) event.preventDefault()
    else this.onItemFocus(item.id)
  }

  /** @internal The arrow keys, Home and End, from an item. */
  onItemKeyDown(event: KeyboardEvent, item: RovingFocusItemState): void {
    if (event.key === 'Tab' && event.shiftKey) {
      // Leave the group in one step: take it out of the tab order until focus has gone.
      this.#isTabbingBackOut = true
      this.#syncGroup()
      return
    }
    if (event.target !== item.element) return
    const intent = getFocusIntent(event, this.orientation, this.dir)
    if (intent === undefined) return
    if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) return
    event.preventDefault()

    let candidates = this.items()
      .filter(other => other.focusable)
      .map(other => other.element)
    if (intent === 'last') candidates.reverse()
    else if (intent === 'prev' || intent === 'next') {
      if (intent === 'prev') candidates.reverse()
      const index = candidates.indexOf(item.element)
      candidates = this.#options.loop?.()
        ? wrap(candidates, index + 1)
        : candidates.slice(index + 1)
    }
    focusFirst(candidates)
  }
}

function groupModifier(roving: RovingFocus): typeof Modifier<RovingFocusGroupModifierSignature> {
  return class RovingFocusGroupModifier extends Modifier<RovingFocusGroupModifierSignature> {
    #installed = false

    override modify(element: HTMLElement): void {
      if (this.#installed) return roving.updateGroup(element)
      this.#installed = true
      const tabindex = element.getAttribute('tabindex')
      const orientation = element.getAttribute('data-orientation')
      roving.updateGroup(element)
      const uninstall = roving.installGroup(element)
      registerDestructor(this, () => {
        uninstall()
        write(element, 'tabindex', tabindex)
        write(element, 'data-orientation', orientation)
      })
    }
  }
}

function itemModifier(roving: RovingFocus): typeof Modifier<RovingFocusItemModifierSignature> {
  return class RovingFocusItemModifier extends Modifier<RovingFocusItemModifierSignature> {
    #item: RovingFocusItemState | undefined

    override modify(
      element: HTMLElement,
      _: [],
      named: RovingFocusItemModifierSignature['Args']['Named'],
    ): void {
      const id = named.tabStopId ?? idFor(this)
      const focusable = named.focusable ?? true
      const active = named.active ?? false

      let item = this.#item
      if (!item) {
        item = this.#item = { element, id, focusable, active }
        this.#install(element, item)
      } else {
        const focusableChanged = item.focusable !== focusable
        Object.assign(item, { id, focusable, active })
        if (focusableChanged) roving.changed()
      }

      // Read here, so the item updates when the tab stop or the orientation changes.
      write(element, 'tabindex', roving.currentTabStopId === id ? '0' : '-1')
      write(element, 'data-orientation', roving.orientation ?? null)
    }

    #install(element: HTMLElement, item: RovingFocusItemState): void {
      const tabindex = element.getAttribute('tabindex')
      const orientation = element.getAttribute('data-orientation')
      const onMouseDown = (event: MouseEvent) => roving.onItemMouseDown(event, item)
      const onFocusIn = () => roving.onItemFocus(item.id)
      const onKeyDown = (event: KeyboardEvent) => roving.onItemKeyDown(event, item)
      element.addEventListener('mousedown', onMouseDown)
      element.addEventListener('focusin', onFocusIn)
      element.addEventListener('keydown', onKeyDown)
      const unregister = roving.register(item)
      registerDestructor(this, () => {
        unregister()
        element.removeEventListener('mousedown', onMouseDown)
        element.removeEventListener('focusin', onFocusIn)
        element.removeEventListener('keydown', onKeyDown)
        write(element, 'tabindex', tabindex)
        write(element, 'data-orientation', orientation)
      })
    }
  }
}

export interface RovingFocusItemSignature<Tag extends keyof HTMLElementTagNameMap = 'span'> {
  Args: {
    /** The item's id, for the tab stop and the harness (`data-test-jn-value`). */
    tabStopId?: string
    /** Whether focus can land on it. Default `true`. */
    focusable?: boolean
    /** Whether Tab enters the group on it first, as on a selected tab. Default `false`. */
    active?: boolean
    /** The tag to render. Default `span`, as in Radix; `button` for a toolbar's buttons. */
    as?: Tag
    /** @internal */
    roving: RovingFocus
  }
  Blocks: {
    default: [state: { isCurrentTabStop: boolean; hasTabStop: boolean }]
  }
  Element: HTMLElementTagNameMap[Tag]
}

/** One item of a `<RovingFocusGroup>`, yielded as `group.Item`. */
class RovingFocusItem<Tag extends keyof HTMLElementTagNameMap = 'span'> extends Component<
  RovingFocusItemSignature<Tag>
> {
  get id(): string {
    return this.args.tabStopId ?? idFor(this)
  }

  /** `@as`, typed as the tag, so the element's type follows it. */
  get tag(): Tag {
    return this.args.as ?? ('span' as Tag)
  }

  get state() {
    const current = this.args.roving.currentTabStopId
    return { isCurrentTabStop: current === this.id, hasTabStop: current !== null }
  }

  <template>
    <As
      @tag={{this.tag}}
      data-test-jn-part="item"
      data-test-jn-value={{this.id}}
      ...attributes
      {{@roving.item tabStopId=this.id focusable=@focusable active=@active}}
    >
      {{yield this.state}}
    </As>
  </template>
}

export interface RovingFocusGroupSignature {
  Args: {
    /** Which arrow keys move focus: `horizontal`, `vertical`, or (unset) all four. */
    orientation?: Orientation
    /** The text direction. Default: the document's, so `dir="rtl"` around it flips the arrows. */
    dir?: Direction
    /** Wrap round from the last item to the first and back. Default `false`. */
    loop?: boolean
    /** The controlled tab stop, by item id. */
    currentTabStopId?: string | null
    /** The first tab stop, uncontrolled. */
    defaultCurrentTabStopId?: string
    /** Called with each new tab stop. */
    onCurrentTabStopIdChange?: (id: string | null) => void
    /** Called before Tab moves focus on to an item; `preventDefault()` keeps it on the group. */
    onEntryFocus?: (event: Event) => void
    /** Don't scroll the item focused on entry into view. */
    preventScrollOnEntryFocus?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** The harness's name for it (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [
      group: {
        /** An item, as an element: `<group.Item @as="button" type="button">`. */
        Item: WithBoundArgs<typeof RovingFocusItem, 'roving'>
        /** An item, as a modifier on your own element: `<button {{group.item}}>`. */
        item: RovingFocus['item']
        /** The id of the item Tab enters on, or `null`. */
        currentTabStopId: string | null
      },
    ]
  }
  Element: HTMLElement
}

/**
 * A roving-tabindex group as a component (see `RovingFocus`): its items share one tab stop, and
 * the arrow keys, Home and End move between them, as in Radix's `RovingFocusGroup`.
 *
 *   <RovingFocusGroup @orientation="horizontal" @loop={{true}} role="toolbar" aria-label="Format" as |group|>
 *     <group.Item @as="button" @tabStopId="bold" type="button">Bold</group.Item>
 *     <button type="button" {{group.item tabStopId="italic"}}>Italic</button>
 *   </RovingFocusGroup>
 */
export class RovingFocusGroup extends Component<RovingFocusGroupSignature> {
  roving = new RovingFocus({
    orientation: () => this.args.orientation,
    dir: () => this.args.dir,
    loop: () => this.args.loop,
    currentTabStopId: () => this.args.currentTabStopId,
    defaultCurrentTabStopId: () => this.args.defaultCurrentTabStopId,
    onCurrentTabStopIdChange: () => this.args.onCurrentTabStopIdChange,
    onEntryFocus: () => this.args.onEntryFocus,
    preventScrollOnEntryFocus: () => this.args.preventScrollOnEntryFocus,
  })

  <template>
    <As
      @as={{@as}}
      @tag="div"
      data-slot="roving-focus-group"
      data-test-jn="roving-focus-group"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.roving.group}}
    >
      {{yield
        (hash
          Item=(component RovingFocusItem roving=this.roving)
          item=this.roving.item
          currentTabStopId=this.roving.currentTabStopId
        )
      }}
    </As>
  </template>
}
