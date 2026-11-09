import Component from '@glimmer/component'
import { cached, tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import type { TOC } from '@ember/component/template-only'
import { buildWaiter } from '@ember/test-waiters'
import Modifier, { modifier } from 'ember-modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { controllable, type ControllableArgs } from './controllable-state.ts'
import { Dialog } from './dialog.gts'
import { idFor } from './id.ts'
import { isMac } from './keys.gts'
import { part, type PartModifier } from './part.ts'
import { VisuallyHidden, visuallyHidden } from './visually-hidden.gts'
import { commandScore } from './-private/command-score.ts'

const waiter = buildWaiter('@ember-joinery/primitives:command')

const ITEM = '[cmdk-item=""]'
const GROUP = '[cmdk-group=""]'
const GROUP_ITEMS = '[cmdk-group-items=""]'
const GROUP_HEADING = '[cmdk-group-heading=""]'

/**
 * How well an item matches the search, from 0 (it doesn't, and is hidden) up: the item's value,
 * what was typed, and the item's keywords. Items show highest first.
 */
export type CommandFilter = (value: string, search: string, keywords: readonly string[]) => number

/**
 * cmdk's own filter, which shadcn's Command uses: a fuzzy match of the typed characters, in
 * order, scoring runs and word starts above skips (see `commandScore` in cmdk). Keywords count
 * as more of the item's text.
 */
export const defaultFilter: CommandFilter = (value, search, keywords) =>
  commandScore(value, search, keywords)

/** The words a screen reader hears when the number of results changes. */
function defaultResultsText(count: number): string {
  return count === 1 ? '1 result' : `${count} results`
}

/** Runs `callback` once the render that called it is over, holding the test waiter till then. */
function afterRender(owner: object, callback: () => void): void {
  const token = waiter.beginAsync()
  queueMicrotask(() => {
    try {
      if (!isDestroying(owner) && !isDestroyed(owner)) callback()
    } finally {
      waiter.endAsync(token)
    }
  })
}

/**
 * cmdk's marker attribute, which shadcn's styles select (`[cmdk-group-heading]`):
 * `{{cmdk "group-heading"}}` gives the element `cmdk-group-heading=""`.
 */
const cmdk = modifier((element: Element, [name]: [string]) => {
  element.setAttribute(`cmdk-${name}`, '')
})

// ----- The hotkey ----------------------------------------------------------------------------

/**
 * Whether a key press is the hotkey: `"mod+k"`, `"ctrl+shift+p"`. `mod` is ⌘ on a Mac and Ctrl
 * everywhere else, as ember-primitives' CommandPalette and `<KeyCombo>` have it; the other
 * modifiers are `meta`, `ctrl`, `alt` and `shift`, and each one not named must be up.
 */
export function matchesHotkey(event: KeyboardEvent, hotkey: string): boolean {
  const parts = hotkey
    .toLowerCase()
    .split('+')
    .map(part => part.trim())
  const key = parts.pop()
  const modifiers = new Set(parts)
  const mod = modifiers.has('mod')
  const mac = isMac()
  return (
    event.key.toLowerCase() === key &&
    event.metaKey === (modifiers.has('meta') || (mod && mac)) &&
    event.ctrlKey === (modifiers.has('ctrl') || (mod && !mac)) &&
    event.altKey === modifiers.has('alt') &&
    event.shiftKey === modifiers.has('shift')
  )
}

interface HotkeySignature {
  Element: Element
  Args: { Positional: [hotkey: string | undefined, callback: (() => void) | undefined] }
}

/**
 * Calls `callback` when the hotkey is pressed anywhere on the page: `{{hotkey "mod+k" this.open}}`
 * on any element, for as long as the element is there. With no hotkey or no callback it listens
 * for nothing.
 */
export class hotkey extends Modifier<HotkeySignature> {
  #hotkey: string | undefined
  #callback: (() => void) | undefined
  #document: Document | undefined

  override modify(element: Element, [hotkey, callback]: HotkeySignature['Args']['Positional']) {
    this.#hotkey = hotkey
    this.#callback = callback
    if (this.#document) return
    const document = (this.#document = element.ownerDocument)
    document.addEventListener('keydown', this.#onKeyDown)
    registerDestructor(this, () => document.removeEventListener('keydown', this.#onKeyDown))
  }

  #onKeyDown = (event: KeyboardEvent): void => {
    const hotkey = this.#hotkey
    const callback = this.#callback
    if (!hotkey || !callback) return
    if (!matchesHotkey(event, hotkey)) return
    event.preventDefault()
    callback()
  }
}

// ----- The state -----------------------------------------------------------------------------

/** What a `<Command>` takes. */
export type CommandArgs = ControllableArgs<'value', string> &
  ControllableArgs<'search', string> & {
    /** The input's name for screen readers, in a visually hidden `<label>`. */
    label?: string
    /** Ranks each item against the search; 0 hides it. Default `defaultFilter`, cmdk's. */
    filter?: CommandFilter
    /** `false` turns filtering and ranking off, for items you filter yourself. Default `true`. */
    shouldFilter?: boolean
    /** Whether the arrow keys wrap round from the last item to the first. Default `false`. */
    loop?: boolean
    /** Whether a pointer moving over an item leaves the selection alone. Default `false`. */
    disablePointerSelection?: boolean
    /** Whether Ctrl+N and Ctrl+J move down, and Ctrl+P and Ctrl+K up, as in Vim. Default `true`. */
    vimBindings?: boolean
    /** Called whenever an item is chosen (a click, or Enter), with its value and the event. */
    onSelect?: (value: string, event: Event) => void
    /** What a screen reader hears as the results change. Default `1 result`, `3 results`. */
    resultsText?: (count: number) => string
    /** A key combination that calls `@onOpen` from anywhere on the page: `"mod+k"`. */
    hotkey?: string
    /** Called when `@hotkey` is pressed. */
    onOpen?: () => void
    /** Its name, for `CommandHarness` (`data-test-jn-name`). */
    name?: string
  }

/** What an item takes. */
export interface CommandItemArgs {
  /**
   * The item's value: what the search is matched against, and what `@onSelect` and the
   * selection hold. Default: its text. Values are trimmed.
   */
  value?: string
  /** More words to match it by, as aliases of its value (`['fruit']` for Apple). */
  keywords?: readonly string[]
  /** Whether it can't be chosen. It still shows, but the keys and the pointer pass over it. */
  disabled?: boolean
  /** Called with its value when it is chosen. */
  onSelect?: (value: string) => void
  /** Show it whatever the search, as cmdk's `forceMount`. */
  forceMount?: boolean
}

/** An item, as the command knows it. */
interface ItemRecord {
  readonly args: () => CommandItemArgs
  /** Its element while it is rendered. */
  element: HTMLElement | null
  /** Its text, kept from when it last rendered, for an item without `@value`. */
  text: string | undefined
  /** The group it was last rendered in. */
  group: HTMLElement | null
}

/** A group, as the command knows it. */
interface GroupRecord {
  readonly args: () => CommandGroupArgs
}

/** What a group takes. */
export interface CommandGroupArgs {
  /** Its heading, which also names its items' `role="group"` for screen readers. */
  heading?: string
  /** Its value, which defaults to its heading (`data-value`). */
  value?: string
  /** Show it whatever the search, as cmdk's `forceMount`. */
  forceMount?: boolean
}

/** What the search leaves: how many items match, each item's score, and the groups shown. */
interface Filtered {
  /** Whether a search is filtering the items now. */
  filtering: boolean
  count: number
  scores: Map<ItemRecord, number>
  groups: Set<HTMLElement>
}

/** The item's value: its `@value`, else its text, trimmed; `undefined` before it has rendered. */
function valueOf(record: ItemRecord): string | undefined {
  const own = record.args().value
  if (own !== undefined) return own.trim()
  return record.text
}

function keywordsOf(record: ItemRecord): string[] {
  return (record.args().keywords ?? []).map(keyword => keyword.trim())
}

/**
 * An item's text, as cmdk reads it (its `textContent`, trimmed), with each run of white space
 * one space: a template keeps the line breaks between an item's icon, text and shortcut, which
 * JSX drops.
 */
function textOf(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** Whether a click opens a link somewhere else (a new tab, a download), leaving the page be. */
function opensElsewhere(event: Event, element: HTMLElement): boolean {
  if (!(event instanceof MouseEvent) || !element.closest('a')) return false
  return event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0
}

/**
 * The elements in the order they show, which a search changes with CSS `order` (see
 * `CommandState#arrange`): by each one's place among its siblings, from `within` down.
 */
function inDisplayOrder<E extends Element>(elements: E[], within: Element): E[] {
  const keys = new Map<E, number[]>()
  for (const element of elements) {
    const key: number[] = []
    for (let node: Element = element; node !== within;) {
      const parent: Element | null = node.parentElement
      if (!parent) break
      const order = node instanceof HTMLElement ? Number(node.style.order) || 0 : 0
      key.unshift(order, Array.prototype.indexOf.call(parent.children, node))
      node = parent
    }
    keys.set(element, key)
  }
  return [...elements].sort((a, b) => {
    const left = keys.get(a)!
    const right = keys.get(b)!
    for (let index = 0; index < Math.min(left.length, right.length); index++) {
      const difference = left[index]! - right[index]!
      if (difference) return difference
    }
    return left.length - right.length
  })
}

/** For `sort()`: `a` before `b` when it comes first in the document. */
function documentOrder(a: Node, b: Node): number {
  return a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
}

/** The child of `container` that holds `element` (or is it). */
function childOf(container: Element, element: Element): HTMLElement | null {
  let node: Element | null = element
  while (node && node.parentElement !== container) node = node.parentElement
  return node as HTMLElement | null
}

/**
 * One command menu's state and behaviour, as cmdk has them: the search, which items it shows
 * and in what order, the selected item, and the keys. `<Command>` makes one, and so does the
 * styled Command in `@ember-joinery/ember`, whose parts are these parts with shadcn's classes.
 */
export class CommandState {
  readonly #owner: { readonly args: CommandArgs }
  /** The selected item's value, or `''` for none: `@value`, `@defaultValue`, `@onValueChange`. */
  readonly selection
  /** The input's text: `@search`, `@defaultSearch`, `@onSearchChange`. */
  readonly searchState

  /** Bumped (after the render) whenever an item or group comes, goes, or changes its text. */
  @tracked private revision = 0

  readonly #items = new Set<ItemRecord>()
  readonly #records = new WeakMap<Element, ItemRecord>()
  readonly #groups = new Map<HTMLElement, GroupRecord>()
  #invalidated = false
  #rootElement: HTMLElement | null = null
  #inputElement: HTMLInputElement | null = null
  #listElement: HTMLElement | null = null
  #sizerElement: HTMLElement | null = null
  /** Whether the next sync selects the first item (the search changed). */
  #selectFirst = false
  #lastSearch = ''
  #settling = false
  /** Whether the next sync scrolls the selected item into view. */
  #scroll = false
  /** What the last arrangement changed: each element's `order`, and the containers it flexed. */
  #ordered = new Set<HTMLElement>()
  #flexed = new Map<HTMLElement, [display: string, direction: string]>()

  constructor(owner: { readonly args: CommandArgs }) {
    this.#owner = owner
    this.selection = controllable(owner as { readonly args: CommandArgs }, 'value', '')
    this.searchState = controllable(owner as { readonly args: CommandArgs }, 'search', '')
  }

  get args(): CommandArgs {
    return this.#owner.args
  }

  get id(): string {
    return idFor(this)
  }

  get inputId(): string {
    return idFor(this, 'input')
  }

  get labelId(): string {
    return idFor(this, 'label')
  }

  get listId(): string {
    return idFor(this, 'list')
  }

  get shouldFilter(): boolean {
    return this.args.shouldFilter !== false
  }

  /** The input's text. */
  get search(): string {
    return this.searchState.value
  }

  /** The selected item's value, or `''` when none is. */
  get value(): string {
    return this.selection.value
  }

  /** Puts text in the input: a search of your own, or a "clear" button. */
  setSearch = (search: string): void => {
    if (search === this.search) return
    this.#selectFirst = true
    this.searchState.set(search)
  }

  /** Selects the item with this value, as the arrow keys do. */
  setValue = (value: string, { scroll = true }: { scroll?: boolean } = {}): void => {
    if (value === this.value) return
    // Focus stays in the input: the root (a click on its padding) gives it back.
    const active = this.#rootElement?.ownerDocument.activeElement
    if (active && active === this.#rootElement) this.#inputElement?.focus()
    this.#scroll = scroll
    this.selection.set(value)
  }

  // ----- What the search shows ---------------------------------------------------------------

  /** Which items the search shows, how they rank, and the groups that have one. */
  @cached
  get filtered(): Filtered {
    void this.revision
    const search = this.search
    const items = [...this.#items].filter(item => !item.args().forceMount)
    const scores = new Map<ItemRecord, number>()
    const groups = new Set<HTMLElement>()
    if (!search || !this.shouldFilter) {
      return { filtering: false, count: items.length, scores, groups }
    }
    let count = 0
    for (const item of items) {
      if (item.element) item.group = item.element.closest(GROUP)
      const score = this.#score(item, search)
      scores.set(item, score)
      if (score <= 0) continue
      count++
      if (item.group) groups.add(item.group)
    }
    return { filtering: true, count, scores, groups }
  }

  /** How many items the search shows (every item, with no search). */
  get count(): number {
    return this.filtered.count
  }

  /** What `role="status"` says, for screen readers. */
  get resultsText(): string {
    return (this.args.resultsText ?? defaultResultsText)(this.count)
  }

  /** An item not rendered yet has no text to match: it shows, so it can render once. */
  #score(item: ItemRecord, search: string): number {
    const value = valueOf(item)
    if (value === undefined) return Infinity
    if (!value) return 0
    return (this.args.filter ?? defaultFilter)(value, search, keywordsOf(item))
  }

  isItemShown = (item: ItemRecord): boolean => {
    if (item.args().forceMount) return true
    const filtered = this.filtered
    if (!filtered.filtering) return true
    const score = filtered.scores.get(item) ?? this.#score(item, this.search)
    return score > 0
  }

  #isGroupShown(group: HTMLElement, record: GroupRecord): boolean {
    const filtered = this.filtered
    return Boolean(record.args().forceMount) || !filtered.filtering || filtered.groups.has(group)
  }

  /** A separator shows while there is no search, as cmdk's. */
  isSeparatorShown = (alwaysRender: boolean | undefined): boolean => {
    return Boolean(alwaysRender) || !this.search
  }

  /** Whether the list shows any option: a result, or an item shown whatever the search. */
  get hasOptions(): boolean {
    return this.count > 0 || [...this.#items].some(item => item.args().forceMount)
  }

  /** Whether nothing matches: Empty shows then. */
  get isEmpty(): boolean {
    return this.count === 0
  }

  /** The id of the selected item while it is rendered, for `aria-activedescendant`. */
  get selectedItemId(): string | undefined {
    const value = this.value
    if (!value) return undefined
    void this.filtered
    const selected = [...this.#items]
      .filter(item => item.element && valueOf(item) === value && this.isItemShown(item))
      .map(item => item.element!)
      .sort(documentOrder)
    return selected[0]?.id
  }

  // ----- Registration ------------------------------------------------------------------------

  /** @internal An item comes; the returned function is for when it goes. */
  registerItem(item: ItemRecord): () => void {
    this.#items.add(item)
    this.#invalidate()
    return () => {
      this.#items.delete(item)
      this.#invalidate()
    }
  }

  /**
   * Registration happens while rendering, and the template has read what it changes, so the
   * change shows in a render of its own, right after.
   */
  #invalidate(): void {
    if (this.#invalidated) return
    this.#invalidated = true
    afterRender(this.#owner, () => {
      this.#invalidated = false
      this.revision++
    })
  }

  // ----- The parts ---------------------------------------------------------------------------

  root: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'cmdk-root': '', tabindex: '-1' },
    on: { keydown: this.#onKeyDown },
    element: element => {
      this.#rootElement = element
      return () => {
        if (this.#rootElement === element) this.#rootElement = null
      }
    },
  }))

  label: PartModifier<HTMLLabelElement> = part<HTMLLabelElement>(() => ({
    attributes: {
      'cmdk-label': '',
      for: this.inputId,
      id: this.labelId,
      'data-test-jn-part': 'label',
    },
  }))

  /**
   * The input: a combobox over the list, as cmdk's, with focus staying in it while
   * `aria-activedescendant` names the selected item. Its text is the search.
   */
  input: PartModifier<HTMLInputElement> = part<HTMLInputElement>(() => {
    const search = this.search
    const input = this.#inputElement
    if (input && input.value !== search) input.value = search
    return {
      attributes: {
        'cmdk-input': '',
        autocomplete: 'off',
        autocorrect: 'off',
        autocapitalize: 'off',
        spellcheck: 'false',
        'aria-autocomplete': 'list',
        role: 'combobox',
        'aria-expanded': 'true',
        'aria-controls': this.listId,
        'aria-labelledby': this.args.label ? this.labelId : undefined,
        'aria-activedescendant': this.selectedItemId,
        id: this.inputId,
        type: 'text',
        'data-test-jn-part': 'input',
      },
      on: {
        input: (event: Event) => {
          const element = event.currentTarget as HTMLInputElement
          this.setSearch(element.value)
          // A search you control and didn't take: the input shows yours again.
          if (!(event as InputEvent).isComposing && element.value !== this.search) {
            element.value = this.search
          }
        },
      },
      element: element => {
        this.#inputElement = element
        if (element.value !== this.search) element.value = this.search
        return () => {
          if (this.#inputElement === element) this.#inputElement = null
        }
      },
    }
  })

  list: PartModifier<HTMLElement, { label?: string }> = part<HTMLElement, { label?: string }>(
    ({ label }) => {
      // A listbox must hold options, so with none to show (only Empty) it is a plain element.
      const listbox = this.hasOptions
      return {
        attributes: {
          'cmdk-list': '',
          role: listbox ? 'listbox' : undefined,
          tabindex: '-1',
          'aria-activedescendant': listbox ? this.selectedItemId : undefined,
          'aria-label': listbox ? (label ?? 'Suggestions') : undefined,
          id: this.listId,
          'data-test-jn-part': 'list',
        },
        element: element => {
          this.#listElement = element
          return () => {
            if (this.#listElement === element) this.#listElement = null
          }
        },
      }
    },
  )

  /** @internal The list's inner element: where items show, and where the command syncs. */
  sizer: typeof Modifier<{ Element: HTMLElement }> = sizerModifier(this)

  /** @internal An item. */
  item: PartModifier<HTMLElement, { record: ItemRecord }> = part<
    HTMLElement,
    { record: ItemRecord }
  >(({ record }) => {
    void this.revision
    const value = valueOf(record) ?? ''
    const disabled = Boolean(record.args().disabled)
    const selected = Boolean(value) && value === this.value
    return {
      attributes: {
        id: idFor(record),
        'cmdk-item': '',
        role: 'option',
        'aria-disabled': String(disabled),
        'aria-selected': String(selected),
        'data-disabled': String(disabled),
        'data-selected': String(selected),
        'data-value': value,
        'data-test-jn-part': 'item',
        'data-test-jn-value': value,
      },
      on: {
        pointermove: () => {
          if (record.args().disabled || this.args.disablePointerSelection) return
          this.setValue(valueOf(record) ?? '', { scroll: false })
        },
        click: (event: MouseEvent) => {
          const element = event.currentTarget as HTMLElement
          if (record.args().disabled || opensElsewhere(event, element)) return
          const chosen = valueOf(record) ?? ''
          this.setValue(chosen, { scroll: false })
          record.args().onSelect?.(chosen)
          this.args.onSelect?.(chosen, event)
        },
      },
      element: element => this.#installItem(record, element),
    }
  })

  /** @internal A group: hidden while the search leaves it nothing. */
  group: PartModifier<HTMLElement, { record: GroupRecord }> = part<
    HTMLElement,
    { record: GroupRecord }
  >(({ record }) => {
    const { heading, value } = record.args()
    const element = [...this.#groups].find(([, other]) => other === record)?.[0]
    return {
      attributes: {
        'cmdk-group': '',
        role: 'presentation',
        hidden: element ? !this.#isGroupShown(element, record) : this.filtered.filtering,
        'data-value': (value ?? heading)?.trim(),
        'data-test-jn-part': 'group',
        'data-test-jn-value': heading,
      },
      element: element => {
        this.#groups.set(element, record)
        this.#invalidate()
        return () => {
          this.#groups.delete(element)
          this.#invalidate()
        }
      },
    }
  })

  /** Keeps what the item's element says, and where it is. */
  #installItem(record: ItemRecord, element: HTMLElement): () => void {
    record.element = element
    this.#records.set(element, record)
    record.group = element.closest(GROUP)
    const read = () => {
      const text = textOf(element)
      if (text === record.text) return
      record.text = text
      this.#invalidate()
    }
    read()
    // An item that has rendered before may come back with nothing new to say.
    this.#invalidate()
    const observer = new MutationObserver(read)
    observer.observe(element, { characterData: true, childList: true, subtree: true })
    return () => {
      observer.disconnect()
      if (record.element === element) record.element = null
    }
  }

  // ----- After each render -------------------------------------------------------------------

  /**
   * @internal Runs after every render that changed the search, the items or the selection,
   * once the DOM shows it: puts the items in the search's order, then, once every part has
   * rendered, selects the first item when the search changed (or what is selected isn't
   * shown), and scrolls the selection into view.
   */
  sync(sizer: HTMLElement): void {
    this.#sizerElement = sizer
    const filtered = this.filtered
    void this.value
    if (this.search !== this.#lastSearch) {
      this.#lastSearch = this.search
      this.#selectFirst = true
    }
    this.#arrange(sizer, filtered)
    if (this.#settling) return
    this.#settling = true
    afterRender(this.#owner, () => {
      this.#settling = false
      this.#settle()
    })
  }

  /** Picks the selection the items now call for, as cmdk does after each change. */
  #settle(): void {
    const value = this.value
    const shown = this.#rendered().some(item => this.#valueOfElement(item) === value)
    if (this.#selectFirst || !value || !shown) {
      this.#selectFirst = false
      const first = this.#navigable()[0]
      const next = first ? this.#valueOfElement(first) : ''
      if (next !== value) return this.setValue(next)
    }
    if (this.#scroll) {
      this.#scroll = false
      this.#scrollIntoView()
    }
  }

  /**
   * While a search filters them, the items show best first, as cmdk sorts them: in each group,
   * and the groups by their best item, with items outside a group before the groups. cmdk moves
   * the elements; Glimmer owns these, so they keep their place in the DOM and show in order
   * through CSS `order`, their container a column of flex items. The keys follow the order
   * they show in, and so does `aria-posinset`.
   */
  #arrange(sizer: HTMLElement, filtered: Filtered): void {
    const ordered = new Set<HTMLElement>()
    const flexed = new Set<HTMLElement>()
    if (filtered.filtering) {
      const flex = (container: HTMLElement) => {
        if (flexed.has(container)) return
        flexed.add(container)
        if (!this.#flexed.has(container)) {
          const { style } = container
          this.#flexed.set(container, [
            style.getPropertyValue('display'),
            style.getPropertyValue('flex-direction'),
          ])
        }
        container.style.setProperty('display', 'flex')
        container.style.setProperty('flex-direction', 'column')
      }
      const counters = new Map<HTMLElement, number>()
      const place = (container: HTMLElement, node: HTMLElement | null) => {
        if (!node) return
        const order = (counters.get(container) ?? 0) + 1
        counters.set(container, order)
        node.style.setProperty('order', String(order))
        ordered.add(node)
        flex(container)
      }

      const shown = [...this.#items].filter(
        item => item.element?.isConnected && sizer.contains(item.element),
      )
      const score = (item: ItemRecord) => filtered.scores.get(item) ?? 0
      // Best first; items that score the same keep their order in the DOM.
      const sorted = shown
        .sort((a, b) => documentOrder(a.element!, b.element!))
        .sort((a, b) => score(b) - score(a))
      for (const item of sorted) {
        const element = item.element!
        const container = (element.closest(GROUP_ITEMS) as HTMLElement | null) ?? sizer
        place(container, childOf(container, element))
      }

      const groups = [...this.#groups.keys()]
        .filter(group => filtered.groups.has(group) && sizer.contains(group))
        .map(group => {
          const best = Math.max(0, ...sorted.filter(i => i.group === group).map(score))
          return [group, best] as const
        })
      for (const [group] of [...groups].sort((a, b) => b[1] - a[1])) {
        place(sizer, childOf(sizer, group))
      }
    }

    for (const node of this.#ordered) {
      if (!ordered.has(node)) node.style.removeProperty('order')
    }
    for (const [container, [display, direction]] of this.#flexed) {
      if (flexed.has(container)) continue
      if (display) container.style.setProperty('display', display)
      else container.style.removeProperty('display')
      if (direction) container.style.setProperty('flex-direction', direction)
      else container.style.removeProperty('flex-direction')
      this.#flexed.delete(container)
    }
    this.#ordered = ordered

    const items = this.#rendered()
    items.forEach((element, index) => {
      if (filtered.filtering) {
        element.setAttribute('aria-posinset', String(index + 1))
        element.setAttribute('aria-setsize', String(items.length))
      } else {
        element.removeAttribute('aria-posinset')
        element.removeAttribute('aria-setsize')
      }
    })
  }

  // ----- The keys ----------------------------------------------------------------------------

  /** Every item this command renders, in the order they show. */
  #rendered(): HTMLElement[] {
    const sizer = this.#sizerElement
    if (!sizer) return []
    const root = sizer.closest('[cmdk-root=""]')
    const items = [...sizer.querySelectorAll<HTMLElement>(ITEM)].filter(
      item => item.closest('[cmdk-root=""]') === root,
    )
    return this.#ordered.size ? inDisplayOrder(items, sizer) : items
  }

  /** The items the keys move between: those rendered that aren't disabled, in order. */
  #navigable(): HTMLElement[] {
    return this.#rendered().filter(item => item.getAttribute('aria-disabled') !== 'true')
  }

  #selected(): HTMLElement | undefined {
    return this.#rendered().find(item => item.getAttribute('aria-selected') === 'true')
  }

  #select(item: HTMLElement | undefined): void {
    if (item) this.setValue(this.#valueOfElement(item))
  }

  /** An item element's value, from what the command knows of it. */
  #valueOfElement(element: Element): string {
    const record = this.#records.get(element)
    return (record ? valueOf(record) : element.getAttribute('data-value')) ?? ''
  }

  /** The item `change` places from the selected one (wrapping round with `@loop`). */
  #move(change: number): void {
    const items = this.#navigable()
    const index = items.indexOf(this.#selected()!)
    let next = items[index + change]
    if (this.args.loop) {
      next =
        index + change < 0
          ? items[items.length - 1]
          : index + change === items.length
            ? items[0]
            : items[index + change]
    }
    this.#select(next)
  }

  /** The first item of the next (or previous) group, or else the next item. */
  #moveGroup(change: number): void {
    const sizer = this.#sizerElement
    const group = this.#selected()?.closest<HTMLElement>(GROUP)
    if (!sizer || !group) return this.#move(change)
    const groups = inDisplayOrder(
      [...sizer.querySelectorAll<HTMLElement>(GROUP)].filter(other => !other.hidden),
      sizer,
    )
    const navigable = this.#navigable()
    for (let index = groups.indexOf(group) + change; index >= 0 && index < groups.length;) {
      const first = navigable.find(item => groups[index]!.contains(item))
      if (first) return this.#select(first)
      index += change
    }
    this.#move(change)
  }

  #last(): void {
    const items = this.#navigable()
    this.#select(items[items.length - 1])
  }

  #next(event: KeyboardEvent): void {
    event.preventDefault()
    if (event.metaKey) this.#last()
    else if (event.altKey) this.#moveGroup(1)
    else this.#move(1)
  }

  #previous(event: KeyboardEvent): void {
    event.preventDefault()
    if (event.metaKey) this.#select(this.#navigable()[0])
    else if (event.altKey) this.#moveGroup(-1)
    else this.#move(-1)
  }

  #onKeyDown = (event: KeyboardEvent): void => {
    // While an input method composes, the keys are its own.
    if (event.isComposing || event.keyCode === 229) return
    const vim = this.args.vimBindings !== false
    switch (event.key) {
      case 'n':
      case 'j':
        if (vim && event.ctrlKey) this.#next(event)
        break
      case 'ArrowDown':
        this.#next(event)
        break
      case 'p':
      case 'k':
        if (vim && event.ctrlKey) this.#previous(event)
        break
      case 'ArrowUp':
        this.#previous(event)
        break
      case 'Home':
        event.preventDefault()
        this.#select(this.#navigable()[0])
        break
      case 'End':
        event.preventDefault()
        this.#last()
        break
      case 'Enter': {
        event.preventDefault()
        // A click, so one handler serves the pointer and the keys, and a link item navigates.
        this.#selected()?.click()
        break
      }
    }
  }

  /** As cmdk: the first item of a group brings its heading into view with it. */
  #scrollIntoView(): void {
    const item = this.#selected()
    if (!item) return
    if (item.parentElement?.firstElementChild === item) {
      item.closest(GROUP)?.querySelector(GROUP_HEADING)?.scrollIntoView({ block: 'nearest' })
    }
    item.scrollIntoView({ block: 'nearest' })
  }

  /** @internal The list's height, as `--cmdk-list-height`, for animating it. */
  measure(sizer: HTMLElement): void {
    this.#listElement?.style.setProperty('--cmdk-list-height', `${sizer.offsetHeight.toFixed(1)}px`)
  }
}

/** The sizer's modifier: syncs the command after each render, and measures the list. */
function sizerModifier(state: CommandState): typeof Modifier<{ Element: HTMLElement }> {
  return class CommandSizer extends Modifier<{ Element: HTMLElement }> {
    #observer: ResizeObserver | undefined

    override modify(element: HTMLElement): void {
      state.sync(element)
      if (this.#observer) return
      const observer = (this.#observer = new ResizeObserver(() => state.measure(element)))
      observer.observe(element)
      registerDestructor(this, () => observer.disconnect())
    }
  }
}

// ----- The part components -------------------------------------------------------------------

export interface CommandInputSignature {
  Args: {
    /** @internal Bound by the command. */
    command: CommandState
  }
  /** A native `<input type="text">`: give it a `placeholder`. */
  Element: HTMLInputElement
}

/** The search box: a combobox over the list. Focus stays in it while the keys move. */
export const CommandInput: TOC<CommandInputSignature> = <template>
  <input ...attributes {{@command.input}} />
</template>

export interface CommandListSignature {
  Args: {
    /** Its name for screen readers. Default `Suggestions`, as cmdk's. */
    label?: string
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by the command. */
    command: CommandState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The listbox the items show in, with an inner element that measures them. */
export const CommandList: TOC<CommandListSignature> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@command.list label=@label}}>
    <div {{cmdk "list-sizer"}} {{@command.sizer}}>{{yield}}</div>
  </As>
</template>

export interface CommandItemSignature {
  Args: CommandItemArgs & {
    /** The tag to render. Default `div`; `a` (with an `href`) for an item that is a link. */
    as?: TagName
    /** @internal Bound by the command. */
    command: CommandState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * An option: chosen with a click or Enter, selected as the pointer moves over it or the keys
 * reach it. It isn't rendered while the search hides it.
 */
export class CommandItem extends Component<CommandItemSignature> {
  record: ItemRecord = { args: () => this.args, element: null, text: undefined, group: null }

  constructor(owner: Owner, args: CommandItemSignature['Args']) {
    super(owner, args)
    registerDestructor(this, args.command.registerItem(this.record))
  }

  <template>
    {{#if (@command.isItemShown this.record)}}
      <As @as={{@as}} @tag="div" ...attributes {{@command.item record=this.record}}>{{yield}}</As>
    {{/if}}
  </template>
}

export interface CommandGroupSignature {
  Args: CommandGroupArgs & {
    /** @internal Bound by the command. */
    command: CommandState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** Items under a heading. It stays rendered, `hidden` while the search leaves it nothing. */
export class CommandGroup extends Component<CommandGroupSignature> {
  record: GroupRecord = { args: () => this.args }

  get headingId(): string {
    return idFor(this.record, 'heading')
  }

  <template>
    <div ...attributes {{@command.group record=this.record}}>
      {{#if @heading}}
        <div
          aria-hidden="true"
          {{cmdk "group-heading"}}
          id={{this.headingId}}
          data-test-jn-part="group-heading"
        >{{@heading}}</div>
      {{/if}}
      <div
        role="group"
        aria-labelledby={{if @heading this.headingId}}
        {{cmdk "group-items"}}
      >{{yield}}</div>
    </div>
  </template>
}

export interface CommandSeparatorSignature {
  Args: {
    /** Show it during a search too. Default: only while there is none, as cmdk's. */
    alwaysRender?: boolean
    /** @internal Bound by the command. */
    command: CommandState
  }
  Element: HTMLDivElement
}

/**
 * A line between groups, shown while there is no search. It is hidden from screen readers: a
 * listbox holds only options and groups, and its groups are named.
 */
export const CommandSeparator: TOC<CommandSeparatorSignature> = <template>
  {{#if (@command.isSeparatorShown @alwaysRender)}}
    <div
      role="separator"
      aria-hidden="true"
      data-test-jn-part="separator"
      ...attributes
      {{cmdk "separator"}}
    ></div>
  {{/if}}
</template>

export interface CommandEmptySignature {
  Args: {
    /** @internal Bound by the command. */
    command: CommandState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** What shows when nothing matches the search. */
export const CommandEmpty: TOC<CommandEmptySignature> = <template>
  {{#if @command.isEmpty}}
    <div
      role="presentation"
      data-test-jn-part="empty"
      ...attributes
      {{cmdk "empty"}}
    >{{yield}}</div>
  {{/if}}
</template>

export interface CommandLoadingSignature {
  Args: {
    /** How far along it is, 0 to 100. */
    progress?: number
    /** Its name for screen readers. Default `Loading...`, as cmdk's. */
    label?: string
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** A progress bar, for while items load: render it while they do, as cmdk's Loading. */
export const CommandLoading: TOC<CommandLoadingSignature> = <template>
  <div
    role="progressbar"
    aria-valuenow={{@progress}}
    aria-valuemin="0"
    aria-valuemax="100"
    aria-label={{if @label @label "Loading..."}}
    data-test-jn-part="loading"
    ...attributes
    {{cmdk "loading"}}
  >
    <div aria-hidden="true">{{yield}}</div>
  </div>
</template>

// ----- Command -------------------------------------------------------------------------------

/** What `<Command>` yields. */
export interface CommandYield {
  /** The search box. */
  Input: WithBoundArgs<typeof CommandInput, 'command'>
  /** The list of items. */
  List: WithBoundArgs<typeof CommandList, 'command'>
  /** An item: `<c.Item @onSelect={{this.run}}>Calendar</c.Item>`. */
  Item: WithBoundArgs<typeof CommandItem, 'command'>
  /** Items under a heading: `<c.Group @heading="Suggestions">`. */
  Group: WithBoundArgs<typeof CommandGroup, 'command'>
  /** A line between groups. */
  Separator: WithBoundArgs<typeof CommandSeparator, 'command'>
  /** What shows when nothing matches. */
  Empty: WithBoundArgs<typeof CommandEmpty, 'command'>
  /** A progress bar for items that are loading. */
  Loading: typeof CommandLoading
  /** Makes an `<input>` of your own the search box: `<input {{c.input}} />`. */
  input: PartModifier<HTMLInputElement>
  /** The input's text. */
  search: string
  /** Puts text in the input. */
  setSearch: (search: string) => void
  /** The selected item's value, or `''`. */
  value: string
  /** Selects an item by its value. */
  setValue: (value: string) => void
  /** How many items the search shows. */
  count: number
}

export interface CommandSignature {
  Args: CommandArgs & {
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [CommandYield] }
  Element: HTMLDivElement
}

/**
 * A command menu: a search box over a list it filters and ranks as you type, as cmdk's
 * (which shadcn's Command is built on), covering ember-primitives' CommandPalette too.
 *
 *   <Command @label="Command Menu" as |c|>
 *     <c.Input placeholder="Type a command or search..." />
 *     <c.List>
 *       <c.Empty>No results found.</c.Empty>
 *       <c.Group @heading="Letters">
 *         <c.Item>a</c.Item>
 *         <c.Item>b</c.Item>
 *       </c.Group>
 *       <c.Separator />
 *       <c.Item @onSelect={{this.eat}}>Apple</c.Item>
 *     </c.List>
 *   </Command>
 *
 * - Typing filters the items by `@filter` (cmdk's fuzzy match by default) and shows the best
 *   first. A group with nothing left hides, and so do the separators; Empty shows when nothing
 *   matches.
 * - One item is selected (`aria-selected`), the first of the results unless the keys or the
 *   pointer move it: ArrowUp and ArrowDown (Ctrl+P and Ctrl+N, Ctrl+K and Ctrl+J), Home and
 *   End, Alt with an arrow for the next group. Enter chooses it. Focus stays in the input.
 * - A `role="status"` says how many results there are, for screen readers.
 */
export class Command extends Component<CommandSignature> {
  state = new CommandState(this)

  setValue = (value: string): void => this.state.setValue(value)

  <template>
    <As
      @as={{@as}}
      @tag="div"
      data-test-jn="command"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.state.root}}
      {{hotkey @hotkey @onOpen}}
    >
      {{#if @label}}
        <label {{this.state.label}} {{visuallyHidden}}>{{@label}}</label>
      {{/if}}
      {{yield
        (hash
          Input=(component CommandInput command=this.state)
          List=(component CommandList command=this.state)
          Item=(component CommandItem command=this.state)
          Group=(component CommandGroup command=this.state)
          Separator=(component CommandSeparator command=this.state)
          Empty=(component CommandEmpty command=this.state)
          Loading=CommandLoading
          input=this.state.input
          search=this.state.search
          setSearch=this.state.setSearch
          value=this.state.value
          setValue=this.setValue
          count=this.state.count
        )
      }}
      <VisuallyHidden
        role="status"
        data-test-jn-part="status"
      >{{this.state.resultsText}}</VisuallyHidden>
    </As>
  </template>
}

// ----- CommandDialog -------------------------------------------------------------------------

/** What `<CommandDialog>` takes. */
export type CommandDialogArgs = ControllableArgs<'open', boolean> & {
  /** The dialog's name for screen readers, visually hidden. Default `Command Palette`. */
  title?: string
  /** Its description, visually hidden. Default `Search for a command to run...`. */
  description?: string
  /** Whether it is modal. Default `true`. */
  modal?: boolean
  /** A key combination that opens and closes it from anywhere on the page: `"mod+k"`. */
  hotkey?: string
  /** Its name, for `CommandDialogHarness` (`data-test-jn-name`). */
  name?: string
}

/** What `<CommandDialog>` yields, to open and close it from inside. */
export interface CommandDialogYield {
  isOpen: boolean
  open: () => void
  toggle: () => void
  setOpen: (open: boolean) => void
}

export interface CommandDialogSignature {
  Args: CommandDialogArgs
  Blocks: { default: [CommandDialogYield] }
  /** The dialog's content. */
  Element: HTMLDivElement
}

/**
 * A `<Command>` in a modal dialog, as cmdk's `Command.Dialog`, on the primitives' Dialog: the
 * overlay, focus moving into the input and back, Escape and a press outside closing it. Put a
 * `<Command>` in it; `@hotkey` opens and closes it from anywhere:
 *
 *   <CommandDialog @hotkey="mod+k" as |d|>
 *     <Command @onSelect={{fn d.setOpen false}} as |c|>…</Command>
 *   </CommandDialog>
 */
export class CommandDialog extends Component<CommandDialogSignature> {
  openState = controllable(this, 'open', false)

  setOpen = (open: boolean): void => this.openState.set(open)
  toggle = (): void => this.openState.set(open => !open)

  <template>
    <Dialog
      @open={{this.openState.value}}
      @onOpenChange={{this.setOpen}}
      @modal={{@modal}}
      @name={{@name}}
      data-test-jn="command-dialog"
      {{hotkey @hotkey this.toggle}}
      as |d|
    >
      <d.Overlay {{cmdk "overlay"}} />
      <d.Content ...attributes {{cmdk "dialog"}}>
        <d.Title {{visuallyHidden}}>{{if @title @title "Command Palette"}}</d.Title>
        <d.Description {{visuallyHidden}}>{{if
            @description
            @description
            "Search for a command to run..."
          }}</d.Description>
        {{yield (hash isOpen=d.isOpen open=d.open toggle=this.toggle setOpen=this.setOpen)}}
      </d.Content>
    </Dialog>
  </template>
}

export default Command
