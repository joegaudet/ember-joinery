import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { array, hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import Modifier, { modifier } from 'ember-modifier'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import type { AnchorOptions, Align, Side } from './anchor/index.ts'
import { ControllableState, controllable, type ControllableArgs } from './controllable-state.ts'
import { getDirection } from './direction.gts'
import { dismissable, type DismissReason } from './dismiss.ts'
import { idFor } from './id.ts'
import { topLayer } from './layer.ts'
import { part, type PartModifier } from './part.ts'
import { Presence } from './presence.gts'
import { ignoreROError } from './resize-observer.ts'
import { Typeahead, getNextMatch } from './typeahead.ts'
import {
  ElementRef,
  anchorContent,
  buttonType,
  displayContents,
  ensureId,
  popperOptions,
} from './-private/popper.gts'
import { translator } from './i18n.ts'

// Base UI's Combobox (@base-ui/react 1.6.0, the version shadcn-ui/ui@8ab2771 pins), which
// shadcn's Combobox is built on: an input that filters a list of items, with the list's
// highlight followed from the keyboard while focus stays in the input (aria-activedescendant),
// one value or several (shown as chips), and the input inside the popup or outside it.

// ----- Items, labels and filtering -----------------------------------------------------------

/** A group of items, as Base UI takes them: `{ value: 'Fruits', items: [...] }`. */
export interface ComboboxItemGroup<T = unknown> {
  value?: unknown
  items: readonly T[]
}

/** Whether `items` is a list of groups (each has `items`), as Base UI decides it. */
export function isGroupedItems(items: readonly unknown[] | undefined): boolean {
  const first = items?.[0]
  return first != null && typeof first === 'object' && 'items' in first
}

function serialize(value: unknown): string {
  if (value == null) return ''
  if (typeof value === 'string') return value
  try {
    return JSON.stringify(value)
  } catch {
    return String(value)
  }
}

/**
 * An item's text, as Base UI's `stringifyAsLabel`: `itemToStringLabel`'s, or else the item's
 * `label`, or its `value`, or the item itself.
 */
export function labelOf(item: unknown, itemToStringLabel?: (item: unknown) => string): string {
  if (itemToStringLabel && item != null) return itemToStringLabel(item) ?? ''
  if (item && typeof item === 'object') {
    const record = item as Record<string, unknown>
    if ('label' in record && record['label'] != null) return String(record['label'])
    if ('value' in record) return String(record['value'])
  }
  return serialize(item)
}

/**
 * An item's form value, as Base UI's `stringifyAsValue`: `itemToStringValue`'s, or else the
 * `value` of an item with a `label` and a `value`, or the item itself.
 */
export function formValueOf(item: unknown, itemToStringValue?: (item: unknown) => string): string {
  if (itemToStringValue && item != null) return itemToStringValue(item) ?? ''
  if (item && typeof item === 'object' && 'value' in item && 'label' in item) {
    return serialize((item as Record<string, unknown>)['value'])
  }
  return serialize(item)
}

/** How Base UI matches text: an `Intl.Collator` for search, ignoring case, accents and punctuation. */
export interface ComboboxFilter {
  contains(text: string, query: string): boolean
  startsWith(text: string, query: string): boolean
  endsWith(text: string, query: string): boolean
}

const filters = new Map<string, ComboboxFilter>()

/**
 * Base UI's collator filter (`useFilter`): `contains`, `startsWith` and `endsWith`, comparing
 * with `Intl.Collator` (`usage: 'search'`, `sensitivity: 'base'`, punctuation ignored), so
 * "e" finds "É" and case doesn't matter.
 */
export function comboboxFilter(options: Intl.CollatorOptions & { locale?: string } = {}) {
  const { locale, ...collatorOptions } = options
  const merged: Intl.CollatorOptions = {
    usage: 'search',
    sensitivity: 'base',
    ignorePunctuation: true,
    ...collatorOptions,
  }
  const key = `${locale ?? ''}|${JSON.stringify(merged)}`
  let filter = filters.get(key)
  if (filter) return filter
  const collator = new Intl.Collator(locale, merged)
  filter = {
    contains(text, query) {
      if (!query) return true
      for (let i = 0; i <= text.length - query.length; i += 1) {
        if (collator.compare(text.slice(i, i + query.length), query) === 0) return true
      }
      return false
    },
    startsWith(text, query) {
      if (!query) return true
      return collator.compare(text.slice(0, query.length), query) === 0
    },
    endsWith(text, query) {
      if (!query) return true
      return (
        text.length >= query.length &&
        collator.compare(text.slice(text.length - query.length), query) === 0
      )
    },
  }
  filters.set(key, filter)
  return filter
}

/** A filter of your own: whether `item` matches `query`. */
export type ComboboxFilterFunction = (
  item: unknown,
  query: string,
  itemToStringLabel?: (item: unknown) => string,
) => boolean

function equal(a: unknown, b: unknown, isEqual: (a: unknown, b: unknown) => boolean): boolean {
  if (a == null || b == null) return Object.is(a, b)
  return isEqual(a, b)
}

// ----- Arguments -----------------------------------------------------------------------------

/** What a `<Combobox>` takes: Base UI's Combobox props, by Joinery's names. */
export type ComboboxArgs = ControllableArgs<'open', boolean> & {
  /**
   * The items, or groups of items (`{ value, items }`), that the list shows and the input
   * filters. Without them, render the items yourself and filter them yourself.
   */
  items?: readonly unknown[]
  /** Items you have filtered yourself, shown instead of filtering `@items` (Base UI's `filteredItems`). */
  filteredItems?: readonly unknown[]
  /** Choose several items, shown as chips. Default `false`. */
  multiple?: boolean
  /** The chosen item (an array of them with `@multiple`), controlled. `null` for none. */
  value?: unknown
  /** The item (or items) chosen to start with, uncontrolled. */
  defaultValue?: unknown
  /** Called with the chosen item (or items) whenever the user changes it. */
  onValueChange?: (value: unknown) => void
  /** The input's text, controlled. */
  inputValue?: string
  /** The input's text to start with. Default: the chosen item's label (one value), or `''`. */
  defaultInputValue?: string
  /** Called with the input's text whenever it changes: typing, choosing, clearing. */
  onInputValueChange?: (value: string) => void
  /**
   * Highlight the first item as the user types, so Enter chooses it. Default `false`
   * (`'always'` keeps an item highlighted whenever the list is open).
   */
  autoHighlight?: boolean | 'always'
  /** An item's text, for the input, the filter and typeahead. Default: its `label`, `value` or itself. */
  itemToStringLabel?: (item: unknown) => string
  /** An item's form value. Default: its `value` (with a `label`), or itself. */
  itemToStringValue?: (item: unknown) => string
  /** Whether an item is the chosen value. Default `Object.is`. */
  isItemEqualToValue?: (item: unknown, value: unknown) => boolean
  /** Your own filter, or `null` to show `@items` unfiltered (for filtering on a server). */
  filter?: ComboboxFilterFunction | null
  /** The most items to show. Default: all. */
  limit?: number
  /** The locale the default filter compares in. Default: the app's translator's. */
  locale?: string
  /** Open the list when the input is pressed. Default `true`. */
  openOnInputClick?: boolean
  /** Highlight the item under the pointer. Default `true`. */
  highlightItemOnHover?: boolean
  /** The arrow keys go round from the last item to the first. Default `true`. */
  loopFocus?: boolean
  /** Disables the input, its buttons and the chips. */
  disabled?: boolean
  /** Shows the value but doesn't let the user change it. */
  readOnly?: boolean
  /** Marks it required (`aria-required`, and the form's hidden input). */
  required?: boolean
  /** The form field's name (Base UI's `name`): hidden inputs carry each value under it. */
  formName?: string
  /** The id of the form the hidden inputs belong to, outside it. */
  form?: string
  /** Its name, for `ComboboxHarness` (`data-test-jn-name`). */
  name?: string
}

/** Where the popup goes: Base UI's positioner arguments. */
export interface ComboboxContentArgs {
  /** The side of the input to place it on. Default `bottom`. */
  side?: Side
  /** Where along that side. Default `center`. */
  align?: Align
  /** The distance from the input, in pixels. Default 0. */
  sideOffset?: number
  /** The shift along the side, in pixels. Default 0. */
  alignOffset?: number
  /** How far from the viewport's edges to stay, in pixels. Default 5. */
  collisionPadding?: number
  /**
   * What to place it against instead of the input: an element, such as the chips (shadcn's
   * `useComboboxAnchor`). The yielded `chipsElement` is the chips container.
   */
  anchor?: Element | null
  /** The tag to render. Default `div`. */
  as?: TagName
}

const CONTENT_DEFAULTS = {
  side: 'bottom',
  align: 'center',
  sideOffset: 0,
  collisionPadding: 5,
} as const

type Reason =
  | 'input-change'
  | 'input-clear'
  | 'input-press'
  | 'item-press'
  | 'clear-press'
  | 'chip-remove-press'
  | 'trigger-press'
  | 'list-navigation'
  | 'escape-key'
  | 'outside-press'
  | 'focus-out'
  | 'none'

/** Whether the input's change came from typing (not autofill), as Base UI tells them apart. */
function isTyped(event: Event | undefined): boolean {
  if (!event) return false
  if (event.type === 'compositionend') return true
  const inputType = (event as InputEvent).inputType
  return inputType != null && inputType !== '' && inputType !== 'insertReplacementText'
}

/** Base UI's anchor custom properties, from the ones `anchor` sets. */
function exposeAnchorProperties(element: HTMLElement): () => void {
  const properties: Array<[string, string]> = [
    ['--anchor-width', 'var(--jn-anchor-width)'],
    ['--anchor-height', 'var(--jn-anchor-height)'],
    ['--available-width', 'var(--jn-anchor-available-width)'],
    ['--available-height', 'var(--jn-anchor-available-height)'],
    ['--transform-origin', 'var(--jn-anchor-transform-origin)'],
  ]
  for (const [property, value] of properties) element.style.setProperty(property, value)
  return () => {
    for (const [property] of properties) element.style.removeProperty(property)
  }
}

function byDocumentOrder(a: { element: Element }, b: { element: Element }): number {
  if (a.element === b.element) return 0
  return a.element.compareDocumentPosition(b.element) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
}

function isInteractive(element: Element | null): boolean {
  return Boolean(element?.closest('button, a[href], input, select, textarea, [role="button"]'))
}

// ----- Items ---------------------------------------------------------------------------------

export interface ComboboxItemSignature {
  Args: {
    /** @internal Bound by the combobox. */
    combobox: Combobox
    /** The item this option chooses: one of `@items`, or a value of your own. */
    value: unknown
    /** Makes it impossible to choose (it can still be highlighted, as Base UI's). */
    disabled?: boolean
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [ComboboxItemBlockParams] }
  Element: HTMLDivElement
}

/** What an item yields: its indicator, bound to it, and its state. */
export interface ComboboxItemBlockParams {
  /** Shown only while the item is chosen, such as a check mark. */
  ItemIndicator: WithBoundArgs<typeof ComboboxItemIndicator, 'item'>
  /** Whether it is chosen. */
  isSelected: boolean
  /** Whether it is highlighted (Base UI's `data-highlighted`). */
  isHighlighted: boolean
}

/**
 * One item, `role="option"`: Base UI's `Combobox.Item`. Focus stays in the input: the item is
 * highlighted (the input's `aria-activedescendant`) by the arrow keys or the pointer, and a
 * press or Enter chooses it.
 */
export class ComboboxItem extends Component<ComboboxItemSignature> {
  element!: HTMLElement
  #pointerStarted = false

  get combobox(): Combobox {
    return this.args.combobox
  }

  get value(): unknown {
    return this.args.value
  }

  get isDisabled(): boolean {
    return this.args.disabled ?? false
  }

  get id(): string {
    return idFor(this)
  }

  get index(): number {
    return this.combobox.trackedItems.indexOf(this)
  }

  get isHighlighted(): boolean {
    const index = this.combobox.activeIndex
    return index !== null && this.combobox.trackedItems[index] === this
  }

  get isSelected(): boolean {
    return this.combobox.isSelected(this.args.value)
  }

  choose = (event: Event): void => {
    if (this.isDisabled || this.combobox.isReadOnly) return
    this.combobox.handleSelection(event, this.args.value)
  }

  part: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.id,
      role: 'option',
      'aria-selected': this.combobox.isSelectable ? String(this.isSelected) : undefined,
      'aria-disabled': this.isDisabled ? 'true' : undefined,
      'data-highlighted': this.isHighlighted,
      'data-selected': this.isSelected,
      'data-disabled': this.isDisabled,
      'data-test-jn-part': 'item',
      'data-test-jn-value': labelOf(this.args.value, this.combobox.args.itemToStringLabel),
    },
    on: {
      // Focus stays in the input: a press on an item doesn't move it.
      pointerdown: event => {
        this.#pointerStarted = true
        event.preventDefault()
      },
      mousedown: event => event.preventDefault(),
      click: this.choose,
      mouseup: event => {
        const started = this.#pointerStarted
        this.#pointerStarted = false
        // A press that started on the input and slid here, released on the highlighted item.
        if (event.button !== 0 || started || !this.isHighlighted) return
        this.choose(event)
      },
      pointermove: () => {
        this.combobox.keyboardActive = false
        if (this.combobox.highlightOnHover && !this.isHighlighted) {
          this.combobox.highlight(this.index)
        }
      },
      pointerleave: () => {
        if (this.combobox.highlightOnHover && this.isHighlighted) this.combobox.highlight(null)
      },
    },
    element: element => {
      this.element = element
      return this.combobox.registerItem(this)
    },
  }))

  <template>
    <As @as={{@as}} @tag="div" ...attributes {{this.part}}>
      {{yield
        (hash
          ItemIndicator=(component ComboboxItemIndicator item=this)
          isSelected=this.isSelected
          isHighlighted=this.isHighlighted
        )
      }}
    </As>
  </template>
}

export interface ComboboxItemIndicatorSignature {
  Args: {
    /** @internal Bound by its item. */
    item: ComboboxItem
    /** The tag to render instead of `span`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/** Base UI's `Combobox.ItemIndicator`: rendered while its item is chosen, hidden from assistive technology. */
const ComboboxItemIndicator: TOC<ComboboxItemIndicatorSignature> = <template>
  {{#if @item.isSelected}}
    <As
      @as={{@as}}
      @tag="span"
      aria-hidden="true"
      data-test-jn-part="item-indicator"
      ...attributes
    >{{yield}}</As>
  {{/if}}
</template>

// ----- Chips ---------------------------------------------------------------------------------

export interface ComboboxChipSignature {
  Args: {
    /** @internal Bound by the combobox. */
    combobox: Combobox
    /** The chosen item this chip shows. */
    value: unknown
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [ComboboxChipBlockParams] }
  Element: HTMLDivElement
}

export interface ComboboxChipBlockParams {
  /** A button that removes the chip's item from the value. */
  Remove: WithBoundArgs<typeof ComboboxChipRemove, 'chip'>
  /** Makes your own element or component the remove button: `<Button {{chip.remove}}>`. */
  remove: PartModifier
}

/**
 * One chosen item, in a multiple combobox: Base UI's `Combobox.Chip`. The arrow keys move
 * between chips (from the input's start), and Backspace or Delete removes one.
 */
export class ComboboxChip extends Component<ComboboxChipSignature> {
  element!: HTMLElement

  get combobox(): Combobox {
    return this.args.combobox
  }

  remove = (event: Event): void => {
    const combobox = this.combobox
    if (combobox.isDisabled || combobox.isReadOnly) return
    combobox.removeChip(this.args.value, 'chip-remove-press')
    event.stopPropagation()
    combobox.inputRef.current?.focus()
  }

  keyDown = (event: KeyboardEvent): void => {
    const combobox = this.combobox
    if (combobox.isDisabled || combobox.isReadOnly) return
    const chips = combobox.chipItems
    const index = chips.indexOf(this)
    const rtl = getDirection(this.element) === 'rtl'
    const previous = rtl ? 'ArrowRight' : 'ArrowLeft'
    const next = rtl ? 'ArrowLeft' : 'ArrowRight'
    let target: number | undefined = index
    if (event.key === previous) {
      event.preventDefault()
      target = index > 0 ? index - 1 : undefined
    } else if (event.key === next) {
      event.preventDefault()
      target = index < chips.length - 1 ? index + 1 : undefined
    } else if (event.key === 'Backspace' || event.key === 'Delete') {
      const count = chips.length
      const after = index >= count - 1 ? count - 2 : index
      target = after >= 0 ? after : undefined
      event.preventDefault()
      event.stopPropagation()
      combobox.highlight(null)
      combobox.removeChip(this.args.value, 'none')
    } else if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      event.stopPropagation()
      target = undefined
    } else if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault()
      event.stopPropagation()
      combobox.setOpen(true, 'list-navigation')
      target = undefined
    } else if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
      // Typing goes back to the input.
      target = undefined
    }
    combobox.highlightedChip = target
    if (target === undefined) combobox.inputRef.current?.focus()
    else queueMicrotask(() => combobox.chipItems[target]?.element.focus())
  }

  part: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      tabindex: '-1',
      'aria-disabled': this.combobox.isDisabled ? 'true' : undefined,
      'aria-readonly': this.combobox.isReadOnly ? 'true' : undefined,
      'data-disabled': this.combobox.isDisabled,
      'data-test-jn-part': 'chip',
      'data-test-jn-value': labelOf(this.args.value, this.combobox.args.itemToStringLabel),
    },
    on: { keydown: this.keyDown },
    element: element => {
      this.element = element
      return this.combobox.registerChip(this)
    },
  }))

  removePart: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      tabindex: '-1',
      'aria-disabled': this.combobox.isDisabled || this.combobox.isReadOnly ? 'true' : undefined,
      'data-test-jn-part': 'chip-remove',
    },
    on: {
      mousedown: event => event.preventDefault(),
      click: this.remove,
      keydown: event => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault()
          this.remove(event)
        }
      },
    },
    element: buttonType,
  }))

  <template>
    <As @as={{@as}} @tag="div" ...attributes {{this.part}}>
      {{yield (hash Remove=(component ComboboxChipRemove chip=this) remove=this.removePart)}}
    </As>
  </template>
}

export interface ComboboxChipRemoveSignature {
  Args: {
    /** @internal Bound by its chip. */
    chip: ComboboxChip
    /** The tag to render instead of `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** Base UI's `Combobox.ChipRemove`: a button, out of the tab order, that removes its chip. */
const ComboboxChipRemove: TOC<ComboboxChipRemoveSignature> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@chip.removePart}}>{{yield}}</As>
</template>

// ----- Simple parts --------------------------------------------------------------------------

export interface ComboboxPartSignature<E extends Element> {
  Args: {
    /** The part's modifier, bound by the combobox. */
    part: PartModifier
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

export interface ComboboxInputSignature {
  Args: {
    /** The input's modifier, bound by the combobox. */
    part: PartModifier<HTMLInputElement>
  }
  Element: HTMLInputElement
}

/** The text input that filters the list: Base UI's `Combobox.Input`. */
const ComboboxInput: TOC<ComboboxInputSignature> = <template>
  <input ...attributes {{@part}} />
</template>

/** A button that opens and closes the list: Base UI's `Combobox.Trigger`. */
const ComboboxTrigger: TOC<ComboboxPartSignature<HTMLButtonElement>> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
</template>

/** A `<div>` that labels the group it is in: Base UI's `Combobox.GroupLabel`. */
const ComboboxGroupLabel: TOC<ComboboxPartSignature<HTMLDivElement>> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@part}}>{{yield}}</As>
</template>

/**
 * A line between items or groups: Base UI's `Combobox.Separator`. Base UI gives it
 * `role="separator"`, which a listbox may not hold (axe's `aria-required-children`), so
 * Joinery's is hidden from assistive technology instead, as Radix's Select separator is.
 */
const ComboboxSeparator: TOC<ComboboxPartSignature<HTMLDivElement>> = <template>
  <As @as={{@as}} @tag="div" aria-hidden="true" ...attributes {{@part}}>{{yield}}</As>
</template>

export interface ComboboxClearSignature {
  Args: {
    /** @internal Bound by the combobox. */
    combobox: Combobox
    /** The tag to render instead of `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * A button that clears the input and the value: Base UI's `Combobox.Clear`. It renders only
 * while there is something to clear.
 */
const ComboboxClear: TOC<ComboboxClearSignature> = <template>
  {{#if @combobox.hasValue}}
    <As @as={{@as}} @tag="button" type="button" ...attributes {{@combobox.clear}}>
      {{~#if (has-block)}}{{yield}}{{else}}x{{/if~}}
    </As>
  {{/if}}
</template>

export interface ComboboxEmptySignature {
  Args: {
    /** @internal Bound by the combobox. */
    combobox: Combobox
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  /** What it says while no item matches. */
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * Says so when no item matches: Base UI's `Combobox.Empty`, a polite live region that shows its
 * block only while the filtered list is empty.
 */
const ComboboxEmpty: TOC<ComboboxEmptySignature> = <template>
  <As
    @as={{@as}}
    @tag="div"
    role="status"
    aria-live="polite"
    aria-atomic="true"
    data-test-jn-part="empty"
    ...attributes
  >{{#if @combobox.isEmpty}}{{yield}}{{/if}}</As>
</template>

export interface ComboboxValueSignature {
  Args: {
    /** @internal Bound by the combobox. */
    combobox: Combobox
    /** What it shows while nothing is chosen. */
    placeholder?: string
  }
  /** Your own rendering of the chosen item (or items, with `@multiple`): `as |value|`. */
  // An item is whatever @items holds, so the template can read its fields.
  Blocks: { default: [value: any] }
}

/**
 * The chosen item's label, or the labels of the chosen items joined by commas, or
 * `@placeholder`: Base UI's `Combobox.Value`. It renders no element. With a block, it yields the
 * value (the array of values, with `@multiple`) to render yourself, as the chips do.
 */
const ComboboxValue: TOC<ComboboxValueSignature> = <template>
  {{~#if (has-block)~}}
    {{yield @combobox.value}}
  {{~else if @combobox.hasValue~}}
    {{@combobox.valueLabel}}
  {{~else~}}
    {{@placeholder}}
  {{~/if~}}
</template>

export interface ComboboxCollectionSignature {
  Args: {
    /** The items to render: a group's (its `@items`), or else the filtered list's. */
    items: readonly unknown[]
  }
  // An item is whatever @items holds, so the template can read its fields.
  Blocks: { default: [item: any, index: number] }
}

/** Base UI's `Combobox.Collection`: renders each item, filtered. */
const ComboboxCollection: TOC<ComboboxCollectionSignature> = <template>
  {{#each @items as |item index|}}{{yield item index}}{{/each}}
</template>

export interface ComboboxGroupSignature {
  Args: {
    /** @internal Bound by the combobox. */
    combobox: Combobox
    /** The group's items, filtered: the `items` of a group the List yields. */
    items?: readonly unknown[]
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [ComboboxGroupBlockParams] }
  Element: HTMLDivElement
}

export interface ComboboxGroupBlockParams {
  /** Renders each of the group's items: `<g.Collection as |item|>`. */
  Collection: WithBoundArgs<typeof ComboboxCollection, 'items'>
}

/** Items that belong together, `role="group"`, named by its label: Base UI's `Combobox.Group`. */
const ComboboxGroup: TOC<ComboboxGroupSignature> = <template>
  <As @as={{@as}} @tag="div" role="group" data-test-jn-part="group" ...attributes>
    {{yield (hash Collection=(component ComboboxCollection items=(if @items @items (array))))}}
  </As>
</template>

export interface ComboboxListSignature {
  Args: {
    /** @internal Bound by the combobox. */
    combobox: Combobox
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  /**
   * Called for each filtered item (or group, when `@items` are groups), as Base UI's List calls
   * its function child: `as |item index|`. Without `@items`, render the items yourself.
   */
  // An item is whatever @items holds, so the template can read its fields.
  Blocks: { default: [item: any, index: number] }
  Element: HTMLDivElement
}

/** The `role="listbox"` that holds the items: Base UI's `Combobox.List`. */
const ComboboxList: TOC<ComboboxListSignature> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@combobox.list}}>
    {{#if @combobox.hasItems}}
      {{#each @combobox.filteredItems as |item index|}}{{yield item index}}{{/each}}
    {{else}}
      {{yield undefined 0}}
    {{/if}}
  </As>
</template>

// ----- Content -------------------------------------------------------------------------------

interface PopupBehaviourSignature {
  Element: HTMLElement
  Args: { Named: { combobox: Combobox } }
}

/**
 * The popup's life: Base UI's anchor custom properties, focus into the input inside it (and
 * back to the trigger) when the input is inside, and what happens once it has gone
 * (`handleUnmount`, after any exit animation).
 */
class PopupBehaviour extends Modifier<PopupBehaviourSignature> {
  #installed = false

  override modify(element: HTMLElement, _: [], { combobox }: { combobox: Combobox }): void {
    if (this.#installed) return
    this.#installed = true
    combobox.popupRef.set(element)
    const restore = exposeAnchorProperties(element)
    // Its width follows its anchor's (`w-(--anchor-width)`), which anchoring sets from a resize
    // observer: the browser's benign "ResizeObserver loop" message follows.
    ignoreROError()
    const onFocus = (event: FocusEvent) => {
      // Focus on the popup itself (or the list) goes to the input.
      const target = event.target as Element
      if (target === element || combobox.listRef.current?.contains(target)) {
        combobox.inputRef.current?.focus()
      }
    }
    element.addEventListener('focusin', onFocus)
    // A popup with the input inside is a dialog, named by its trigger unless the caller named it.
    const named = element.hasAttribute('aria-label') || element.hasAttribute('aria-labelledby')
    let restoreTriggerId = () => {}
    const trigger = combobox.triggerRef.current
    if (combobox.inputInsidePopup && !named && trigger) {
      restoreTriggerId = ensureId(trigger, idFor(combobox, 'trigger'))
      element.setAttribute('aria-labelledby', trigger.id)
    }
    if (combobox.inputInsidePopup) {
      queueMicrotask(() => {
        if (combobox.isOpen) combobox.inputRef.current?.focus()
      })
    }
    registerDestructor(this, () => {
      element.removeEventListener('focusin', onFocus)
      if (!named) element.removeAttribute('aria-labelledby')
      restoreTriggerId()
      restore()
      // Its input may have gone already, taking focus with it to the body.
      const active = document.activeElement
      const focusInside = element.contains(active) || active === document.body || !active
      combobox.popupRef.release(element)
      if (combobox.inputInsidePopup && focusInside) combobox.triggerRef.current?.focus()
      combobox.unmounted()
    })
  }
}

export interface ComboboxContentSignature {
  Args: ComboboxContentArgs & {
    /** @internal Bound by the combobox. */
    combobox: Combobox
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The popup: Base UI's `Combobox.Positioner` and `Combobox.Popup` as one element, in the
 * browser's top layer while open (and while it animates out), placed below the input (or the
 * trigger, when the input is inside it, or `@anchor`). A press outside, Escape or focus leaving
 * closes it.
 */
export class ComboboxContent extends Component<ComboboxContentSignature> {
  get combobox(): Combobox {
    return this.args.combobox
  }

  get anchorOptions(): AnchorOptions {
    // Base UI's positioner doesn't keep the popup on its anchor (`sticky` off).
    return popperOptions(this.args, {}, CONTENT_DEFAULTS, {})
  }

  get reference(): Element | null {
    return this.args.anchor ?? this.combobox.anchorElement
  }

  dismiss = (reason: DismissReason): void => {
    this.combobox.setOpen(false, reason === 'escape-key' ? 'escape-key' : 'outside-press')
  }

  <template>
    <Presence @present={{@combobox.isOpen}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        data-jn-combobox-popup
        ...attributes
        {{presence.ref}}
        {{@combobox.popup}}
        {{topLayer}}
        {{anchorContent this.reference this.anchorOptions}}
        {{dismissable
          enabled=@combobox.isOpen
          onDismiss=this.dismiss
          inside=@combobox.insideElements
        }}
        {{PopupBehaviour combobox=@combobox}}
      >{{yield}}</As>
    </Presence>
  </template>
}

// ----- The combobox --------------------------------------------------------------------------

/** What a `<Combobox>` yields: its parts, their modifiers, and its state. */
export interface ComboboxBlockParams {
  /** The `<input>` that filters the list. For your own input, use `input`. */
  Input: WithBoundArgs<typeof ComboboxInput, 'part'>
  /** A button that opens and closes the list. */
  Trigger: WithBoundArgs<typeof ComboboxTrigger, 'part'>
  /** A button that clears the input and the value, rendered while there is a value. */
  Clear: WithBoundArgs<typeof ComboboxClear, 'combobox'>
  /** The chosen item's label, or a block to render the value yourself. */
  Value: WithBoundArgs<typeof ComboboxValue, 'combobox'>
  /** The popup, in the top layer while open. */
  Content: WithBoundArgs<typeof ComboboxContent, 'combobox'>
  /** The `listbox`, which yields each filtered item. */
  List: WithBoundArgs<typeof ComboboxList, 'combobox'>
  /** One item. */
  Item: WithBoundArgs<typeof ComboboxItem, 'combobox'>
  /** Items that belong together. */
  Group: WithBoundArgs<typeof ComboboxGroup, 'combobox'>
  /** The label of the group it is in. */
  GroupLabel: WithBoundArgs<typeof ComboboxGroupLabel, 'part'>
  /** Renders each item of the filtered list (or of `@items`). */
  Collection: typeof ComboboxCollection
  /** What it says when nothing matches. */
  Empty: WithBoundArgs<typeof ComboboxEmpty, 'combobox'>
  /** A line between items or groups. */
  Separator: WithBoundArgs<typeof ComboboxSeparator, 'part'>
  /** The chips of a multiple combobox, around them and their input. */
  chips: PartModifier
  /** One chip: a chosen item. */
  Chip: WithBoundArgs<typeof ComboboxChip, 'combobox'>
  /** Makes your own input the combobox's: `<input {{c.input}}>`. */
  input: PartModifier<HTMLInputElement>
  /** Makes your own element or component the trigger: `<Button {{c.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element or component the clear button. */
  clear: PartModifier
  /** The chips' element, to place the popup against (`@anchor`), as `useComboboxAnchor`. */
  chipsElement: HTMLElement | null
  /** The chosen item, or items. */
  value: unknown
  /** The input's text. */
  inputValue: string
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
  /** Chooses an item (or items). */
  setValue: (value: unknown) => void
}

export interface ComboboxSignature {
  Args: ComboboxArgs
  Blocks: { default: [ComboboxBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * An input with a list of suggestions: Base UI's Combobox, which shadcn's is built on. It
 * renders no box of its own, and yields its parts:
 *
 *   <Combobox @items={{frameworks}} as |c|>
 *     <c.Input placeholder="Select a framework" />
 *     <c.Content>
 *       <c.Empty>No items found.</c.Empty>
 *       <c.List as |item|>
 *         <c.Item @value={{item}}>{{item}}</c.Item>
 *       </c.List>
 *     </c.Content>
 *   </Combobox>
 *
 * Typing filters `@items` (an `Intl.Collator` match anywhere in the label, as Base UI's) and
 * opens the list; the arrow keys highlight an item while focus stays in the input, and Enter or
 * a press chooses it. With `@multiple` the value is an array, shown as chips.
 */
export class Combobox extends Component<ComboboxSignature> {
  openState = controllable(this, 'open', false)
  valueState: ControllableState<unknown>
  inputState: ControllableState<string>
  inputRef = new ElementRef<HTMLInputElement>()
  triggerRef = new ElementRef()
  clearRef = new ElementRef()
  chipsRef = new ElementRef()
  popupRef = new ElementRef()
  listRef = new ElementRef()

  /** The highlighted item's index among the rendered items, or `null`. */
  @tracked activeIndex: number | null = null
  /** Whether the user has typed a query since the list opened. */
  @tracked queryChangedAfterOpen = false
  /** The query frozen while the list animates out, so it doesn't refilter as it goes. */
  @tracked closeQuery: string | null = null
  /** Whether an input outside the popup has registered (so the input isn't inside it). */
  @tracked hasOutsideInput = false
  /** The chip that has focus, for the arrow keys. */
  highlightedChip: number | undefined
  /** Whether the last interaction was the keyboard, for how a highlight is reported. */
  keyboardActive = true
  /** The key that opened the list, which decides the first highlight. */
  #openKey: string | null = null
  #hadInputClear = false
  #triggerTypeahead = new Typeahead()

  #items = new Set<ComboboxItem>()
  #chips = new Set<ComboboxChip>()
  @tracked private itemsVersion = 0
  #bumping = false

  constructor(owner: Owner, args: ComboboxArgs) {
    super(owner, args)
    this.valueState = new ControllableState<unknown>({
      name: 'value',
      value: () => this.args.value,
      defaultValue: () => this.args.defaultValue,
      onChange: () => this.args.onValueChange,
      fallback: args.multiple ? [] : null,
    })
    this.inputState = new ControllableState<string>({
      name: 'inputValue',
      value: () => this.args.inputValue,
      defaultValue: () => this.initialInputValue,
      onChange: () => this.args.onInputValueChange,
      fallback: '',
    })
    registerDestructor(this, () => this.#triggerTypeahead.dispose())
  }

  /** Without `@inputValue` or `@defaultInputValue`, a single combobox's input starts with its value's label. */
  get initialInputValue(): string | undefined {
    const args = this.args
    if (args.inputValue !== undefined || args.defaultInputValue !== undefined) {
      return args.defaultInputValue
    }
    if (this.isSingle) return labelOf(this.valueState.value, args.itemToStringLabel)
    return undefined
  }

  get id(): string {
    return idFor(this)
  }

  get listId(): string {
    return idFor(this, 'list')
  }

  get popupId(): string {
    return idFor(this, 'popup')
  }

  // ----- State ---------------------------------------------------------------------------------

  get isOpen(): boolean {
    return this.openState.value
  }

  get isMultiple(): boolean {
    return this.args.multiple ?? false
  }

  get isSingle(): boolean {
    return !this.isMultiple
  }

  get isSelectable(): boolean {
    return true
  }

  get isDisabled(): boolean {
    return this.args.disabled ?? false
  }

  get isReadOnly(): boolean {
    return this.args.readOnly ?? false
  }

  get highlightOnHover(): boolean {
    return this.args.highlightItemOnHover ?? true
  }

  get loopFocus(): boolean {
    return this.args.loopFocus ?? true
  }

  get autoHighlight(): false | 'input-change' | 'always' {
    const auto = this.args.autoHighlight
    if (auto === 'always') return 'always'
    return auto ? 'input-change' : false
  }

  get value(): unknown {
    return this.valueState.value
  }

  get values(): unknown[] {
    const value = this.value
    return Array.isArray(value) ? value : []
  }

  get inputValue(): string {
    return this.inputState.value
  }

  /** Whether the input is inside the popup (as in shadcn's "Popup" example): no input outside it. */
  get inputInsidePopup(): boolean {
    return !this.hasOutsideInput
  }

  get isEqual(): (a: unknown, b: unknown) => boolean {
    return this.args.isItemEqualToValue ?? Object.is
  }

  isSelected(item: unknown): boolean {
    if (this.isMultiple) return this.values.some(value => equal(item, value, this.isEqual))
    return equal(item, this.value, this.isEqual)
  }

  /** Whether there is a value to clear (and so whether Clear renders). */
  get hasValue(): boolean {
    if (this.isMultiple) return this.values.length > 0
    return this.value != null
  }

  /** The chosen item's label, or the chosen items' labels joined by commas. */
  get valueLabel(): string {
    const toLabel = this.args.itemToStringLabel
    if (this.isMultiple) return this.values.map(value => labelOf(value, toLabel)).join(', ')
    return this.value == null ? '' : labelOf(this.value, toLabel)
  }

  // ----- Filtering -----------------------------------------------------------------------------

  get hasItems(): boolean {
    return this.args.items !== undefined || this.args.filteredItems !== undefined
  }

  get isGrouped(): boolean {
    return isGroupedItems(this.args.items)
  }

  get query(): string {
    if (this.closeQuery !== null) return this.closeQuery
    const value = this.inputValue
    return value === '' ? '' : value.trim()
  }

  get collator(): ComboboxFilter {
    return comboboxFilter({ locale: this.args.locale ?? translator(this)?.locale })
  }

  get selectedLabel(): string {
    return this.isSingle ? labelOf(this.value, this.args.itemToStringLabel) : ''
  }

  /**
   * Whether to show every item though there is a query: a single combobox's input shows its
   * value's label, which the user hasn't changed since it opened.
   */
  get bypassesFiltering(): boolean {
    const query = this.query
    const selected = this.selectedLabel
    return (
      this.isSingle &&
      !this.queryChangedAfterOpen &&
      query !== '' &&
      selected !== '' &&
      selected.length === query.length &&
      this.collator.contains(selected, query)
    )
  }

  get filter(): ComboboxFilterFunction {
    const own = this.args.filter
    if (own === null) return () => true
    if (own !== undefined) return own
    const collator = this.collator
    const toLabel = this.args.itemToStringLabel
    if (this.isSingle && !this.queryChangedAfterOpen) {
      const selected = this.value
      return (item, query) => {
        if (item == null) return false
        if (!query) return true
        const text = labelOf(item, toLabel)
        const selectedText = selected != null ? labelOf(selected, toLabel) : ''
        if (selectedText && collator.contains(selectedText, query)) {
          if (selectedText.length === query.length) return true
        }
        return collator.contains(text, query)
      }
    }
    return item => item != null && collator.contains(labelOf(item, toLabel), this.query)
  }

  /** What the list shows: the filtered items (or groups of them), limited to `@limit`. */
  get filteredItems(): readonly unknown[] {
    const args = this.args
    if (args.filteredItems && !(args.items && this.bypassesFiltering)) return args.filteredItems
    const items = args.items
    if (!items) return []
    const query = this.bypassesFiltering ? '' : this.query
    const limit = args.limit ?? -1
    const filter = this.filter
    const toLabel = args.itemToStringLabel
    const matches = (item: unknown) => query === '' || filter(item, query, toLabel)
    if (this.isGrouped) {
      const groups: ComboboxItemGroup[] = []
      let count = 0
      for (const group of items as readonly ComboboxItemGroup[]) {
        if (limit > -1 && count >= limit) break
        const candidates = group.items.filter(matches)
        if (!candidates.length) continue
        const taken = limit > -1 ? candidates.slice(0, limit - count) : candidates
        groups.push({ ...group, items: taken })
        count += taken.length
      }
      return groups
    }
    const result: unknown[] = []
    for (const item of items) {
      if (limit > -1 && result.length >= limit) break
      if (matches(item)) result.push(item)
    }
    return result
  }

  get flatFilteredItems(): readonly unknown[] {
    const items = this.filteredItems
    return this.isGrouped && !this.args.filteredItems
      ? (items as readonly ComboboxItemGroup[]).flatMap(group => group.items)
      : items
  }

  get isEmpty(): boolean {
    if (!this.hasItems) return false
    return this.flatFilteredItems.length === 0
  }

  // ----- Items and chips -----------------------------------------------------------------------

  /** The items rendered now, in document order. */
  get items(): ComboboxItem[] {
    return [...this.#items].filter(item => item.element).sort(byDocumentOrder)
  }

  get trackedItems(): ComboboxItem[] {
    void this.itemsVersion
    return this.items
  }

  get chipItems(): ComboboxChip[] {
    return [...this.#chips].filter(chip => chip.element).sort(byDocumentOrder)
  }

  registerItem(item: ComboboxItem): () => void {
    this.#items.add(item)
    this.#bump()
    return () => {
      this.#items.delete(item)
      this.#bump()
    }
  }

  registerChip(chip: ComboboxChip): () => void {
    this.#chips.add(chip)
    return () => void this.#chips.delete(chip)
  }

  #bump(): void {
    if (this.#bumping) return
    this.#bumping = true
    queueMicrotask(() => {
      this.#bumping = false
      if (this.isDestroying || this.isDestroyed) return
      this.itemsVersion += 1
      this.#settleHighlight()
    })
  }

  /** The highlighted item, if any. */
  get activeItem(): ComboboxItem | undefined {
    const index = this.activeIndex
    return index === null ? undefined : this.trackedItems[index]
  }

  /** The index of the (last) chosen item among the rendered items, or `null`. */
  get selectedIndex(): number | null {
    const items = this.items
    const target = this.isMultiple ? this.values.at(-1) : this.value
    if (target == null) return null
    const index = items.findIndex(item => equal(item.value, target, this.isEqual))
    return index === -1 ? null : index
  }

  highlight = (index: number | null): void => {
    if (this.activeIndex !== index) this.activeIndex = index
    if (index !== null) this.items[index]?.element.scrollIntoView?.({ block: 'nearest' })
  }

  /** After the items change: keep the highlight in range, or make the first one. */
  #settleHighlight(): void {
    const count = this.items.length
    // With @items, the filtered data says how many there are, rendered or not yet.
    const available = this.hasItems ? this.flatFilteredItems.length : count
    const index = this.activeIndex
    if (index !== null && index >= available) this.activeIndex = null
    if (this.isOpen && this.activeIndex === null && count > 0) {
      if (this.autoHighlight === 'always') this.activeIndex = 0
      else if (this.#openKey !== null) {
        // Opened from the keyboard: the chosen item, or the first (the last for ArrowUp).
        this.activeIndex = this.selectedIndex ?? (this.#openKey === 'ArrowUp' ? count - 1 : 0)
      } else if (!this.queryChangedAfterOpen && this.selectedIndex !== null) {
        this.activeIndex = this.selectedIndex
      }
      this.#openKey = null
    }
    if (this.isMultiple && this.isEmpty && this.autoHighlight) this.activeIndex = null
  }

  // ----- Changes -------------------------------------------------------------------------------

  setInputValue(next: string, reason: Reason, event?: Event): void {
    this.#hadInputClear = reason === 'input-clear'
    if (reason === 'input-change' && isTyped(event)) {
      const hasQuery = next.trim() !== ''
      if (hasQuery) this.queryChangedAfterOpen = true
      if (hasQuery && this.autoHighlight) this.activeIndex = 0
    }
    this.inputState.set(next)
  }

  setOpen = (next: boolean, reason: Reason = 'none'): void => {
    if (this.isOpen === next) return
    if (next && this.isMultiple && this.inputInsidePopup && this.closeQuery !== null) {
      this.queryChangedAfterOpen = false
      this.closeQuery = null
      if (this.inputValue !== '') this.setInputValue('', 'input-clear')
    }
    if (!next && this.queryChangedAfterOpen) {
      if (this.isSingle) {
        this.closeQuery = this.query
        if (this.query === '') this.queryChangedAfterOpen = false
      } else {
        this.closeQuery = this.query
        if (this.inputInsidePopup) this.activeIndex = null
        else this.setInputValue('', 'input-clear')
      }
    }
    if (next && reason !== 'list-navigation') this.#openKey = null
    this.openState.set(next)
    if (next) queueMicrotask(() => this.#settleHighlight())
  }

  setSelectedValue(next: unknown, reason: Reason): void {
    this.valueState.set(next)
    if (this.isSingle && !this.inputInsidePopup) {
      this.setInputValue(labelOf(next, this.args.itemToStringLabel), reason)
    }
    if (this.isSingle && next != null && reason !== 'input-change' && this.queryChangedAfterOpen) {
      this.closeQuery = this.query
    }
  }

  setValue = (value: unknown): void => this.setSelectedValue(value, 'none')

  /** An item was chosen: Base UI's `handleSelection`. */
  handleSelection(event: Event, item: unknown): void {
    const link = (event.target as Element | null)?.closest?.('a')?.getAttribute('href')
    if (link) {
      if (link.startsWith('#')) this.setOpen(false, 'item-press')
      return
    }
    if (this.isMultiple) {
      const current = this.values
      const chosen = current.some(value => equal(item, value, this.isEqual))
      const next = chosen
        ? current.filter(value => !equal(item, value, this.isEqual))
        : [...current, item]
      this.setSelectedValue(next, 'item-press')
      const wasFiltering = (this.inputRef.current?.value.trim() ?? '') !== ''
      if (!wasFiltering) return
      if (this.inputInsidePopup) this.setInputValue('', 'input-clear')
      else this.setOpen(false, 'item-press')
    } else {
      this.setSelectedValue(item, 'item-press')
      this.setOpen(false, 'item-press')
    }
  }

  removeChip(value: unknown, reason: Reason): void {
    const active = this.activeItem
    if (active && equal(active.value, value, this.isEqual)) this.highlight(null)
    this.setSelectedValue(
      this.values.filter(item => !equal(item, value, this.isEqual)),
      reason,
    )
  }

  /** The popup has gone (after any exit animation): Base UI's `handleUnmount`. */
  unmounted(): void {
    if (this.isDestroying || this.isDestroyed) return
    this.queryChangedAfterOpen = false
    this.closeQuery = null
    this.activeIndex = null
    const input = this.inputRef.current
    if (this.isMultiple && input && input.value !== '' && !this.#hadInputClear) {
      this.setInputValue('', 'input-clear')
    }
    if (this.isSingle) {
      if (this.inputInsidePopup) {
        if (this.inputValue !== '') this.setInputValue('', 'input-clear')
      } else {
        const label = labelOf(this.value, this.args.itemToStringLabel)
        if (this.inputValue !== label)
          this.setInputValue(label, label === '' ? 'input-clear' : 'none')
      }
    }
  }

  // ----- Keyboard --------------------------------------------------------------------------------

  /** Base UI's list navigation, virtual: the arrows move the highlight, focus stays in the input. */
  navigate(event: KeyboardEvent): void {
    const forward = event.key === 'ArrowDown'
    if (!this.isOpen) {
      this.#openKey = event.key
      this.setOpen(true, 'list-navigation')
      return
    }
    const count = this.items.length
    if (!count) return
    const allowEscape = this.loopFocus && !this.autoHighlight
    let index = this.activeIndex ?? -1
    const max = count - 1
    if (forward) {
      if (this.loopFocus && index >= max) index = allowEscape && index !== count ? -1 : 0
      else index = Math.min(max, index + 1)
    } else if (this.loopFocus && index <= 0) {
      index = allowEscape && index !== -1 ? -1 : max
    } else {
      index = Math.max(0, index - 1)
    }
    this.highlight(index === -1 ? null : index)
  }

  inputKeyDown = (event: KeyboardEvent): void => {
    if (this.isDisabled || this.isReadOnly) return
    if (event.ctrlKey || event.shiftKey || event.altKey || event.metaKey) return
    this.keyboardActive = true
    const input = event.currentTarget as HTMLInputElement
    if (event.key === 'Home' || event.key === 'End') {
      // They move the caret, not the highlight.
      event.preventDefault()
      event.stopPropagation()
      const end = event.key === 'End'
      const cursor = end ? input.value.length : 0
      input.setSelectionRange(cursor, cursor)
      return
    }
    if (!this.isOpen && event.key === 'Escape') {
      // Escape on the closed list clears the input and the value.
      const wasClear = !this.hasValue
      this.setInputValue('', 'escape-key')
      this.setSelectedValue(this.isMultiple ? [] : null, 'escape-key')
      if (!wasClear) event.stopPropagation()
      return
    }
    if (this.chipsRef.current) {
      if (this.#chipKeyDown(event, input)) return
    }
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault()
      event.stopPropagation()
      this.navigate(event)
      return
    }
    if (event.key === 'Enter' && this.isOpen) {
      const item = this.activeItem
      // With nothing highlighted, Enter closes it and submits the form.
      if (!item) return this.setOpen(false, 'none')
      event.preventDefault()
      event.stopPropagation()
      item.element.click()
    }
  }

  /** The input's keys among chips: Backspace removes the last, the start arrow moves into them. */
  #chipKeyDown(event: KeyboardEvent, input: HTMLInputElement): boolean {
    const chips = this.chipItems
    const values = this.values
    if (event.key === 'Backspace' && input.value === '' && values.length > 0) {
      event.preventDefault()
      this.highlight(null)
      const last = chips.at(-1)?.args.value ?? values.at(-1)
      this.setSelectedValue(
        values.filter(value => value !== last),
        'none',
      )
      return true
    }
    const rtl = getDirection(input) === 'rtl'
    const previous = rtl ? 'ArrowRight' : 'ArrowLeft'
    if (event.key === previous && (input.selectionStart ?? 0) === 0 && chips.length > 0) {
      event.preventDefault()
      this.highlightedChip = chips.length - 1
      chips.at(-1)?.element.focus()
      return true
    }
    return false
  }

  onInput = (event: Event): void => {
    const input = event.currentTarget as HTMLInputElement
    const value = input.value
    this.setInputValue(value, 'input-change', event)
    if (value === '' && !this.inputInsidePopup) {
      if (this.isSingle) this.setSelectedValue(null, 'input-clear')
      if (!(this.args.openOnInputClick ?? true)) this.setOpen(false, 'input-clear')
    }
    const trimmed = value.trim()
    const typed = isTyped(event)
    if (!this.isReadOnly && !this.isDisabled && trimmed && typed) {
      this.setOpen(true, 'input-change')
      if (!this.autoHighlight) this.activeIndex = null
    }
    if (this.isOpen && this.activeIndex !== null && !this.autoHighlight) this.activeIndex = null
  }

  /** A press on the input (or the chips) opens the list, as Base UI's `useClick` on mousedown. */
  inputPress = (event: MouseEvent): void => {
    if (this.isReadOnly || this.isDisabled || event.button !== 0) return
    this.keyboardActive = false
    if (this.args.openOnInputClick ?? true) this.setOpen(true, 'input-press')
  }

  // ----- The parts' modifiers ------------------------------------------------------------------

  input: PartModifier<HTMLInputElement> = part<HTMLInputElement>(() => {
    const open = this.isOpen
    const active = open ? this.activeItem : undefined
    return {
      attributes: {
        role: 'combobox',
        type: 'text',
        autocomplete: 'off',
        spellcheck: 'false',
        autocorrect: 'off',
        autocapitalize: 'none',
        'aria-expanded': String(open),
        'aria-haspopup': 'listbox',
        'aria-controls': open ? this.listId : undefined,
        'aria-autocomplete': 'list',
        'aria-activedescendant': active?.id,
        'aria-readonly': this.isReadOnly ? 'true' : undefined,
        'aria-required': this.args.required ? 'true' : undefined,
        disabled: this.isDisabled,
        readonly: this.isReadOnly,
        'data-popup-open': open,
        'data-pressed': open,
        'data-list-empty': this.isEmpty,
        'data-disabled': this.isDisabled,
        'data-readonly': this.isReadOnly,
        'data-test-jn-part': 'input',
      },
      on: {
        input: this.onInput,
        keydown: this.inputKeyDown,
        mousedown: this.inputPress,
        pointerdown: () => (this.keyboardActive = false),
        pointermove: () => (this.keyboardActive = false),
      },
      element: element => {
        this.inputRef.set(element)
        // Inside the popup, or outside it: what the trigger and the popup do depends on it.
        const outside = !element.closest('[data-jn-combobox-popup]')
        if (outside) queueMicrotask(() => (this.hasOutsideInput = true))
        // An input inside the popup starts empty, for a search, unless its text is given.
        const given =
          this.args.inputValue !== undefined || this.args.defaultInputValue !== undefined
        if (!outside && !given && this.inputValue !== '') {
          queueMicrotask(() => this.setInputValue('', 'none'))
        }
        element.value = outside || given ? this.inputValue : ''
        return () => {
          this.inputRef.release(element)
          if (outside) queueMicrotask(() => (this.hasOutsideInput = false))
        }
      },
    }
  })

  trigger: PartModifier = part<HTMLElement>(() => {
    const open = this.isOpen
    const insidePopup = this.inputInsidePopup
    return {
      attributes: {
        tabindex: insidePopup ? '0' : '-1',
        role: insidePopup ? 'combobox' : undefined,
        'aria-expanded': String(open),
        'aria-haspopup': insidePopup ? 'dialog' : 'listbox',
        'aria-controls': open ? (insidePopup ? this.popupId : this.listId) : undefined,
        'aria-required': insidePopup && this.args.required ? 'true' : undefined,
        disabled: this.isDisabled,
        'data-popup-open': open,
        'data-pressed': open,
        'data-disabled': this.isDisabled,
        'data-placeholder': !this.hasValue,
        'data-test-jn-part': 'trigger',
      },
      on: {
        mousedown: event => {
          if (this.isDisabled || this.isReadOnly || event.button !== 0) return
          if (!insidePopup) {
            // Focus goes to the input, not the trigger.
            this.inputRef.current?.focus()
            event.preventDefault()
          }
          this.setOpen(!this.isOpen, 'trigger-press')
        },
        keydown: event => {
          if (this.isDisabled || this.isReadOnly) return
          if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
            event.preventDefault()
            event.stopPropagation()
            this.#openKey = event.key
            this.setOpen(true, 'list-navigation')
            this.inputRef.current?.focus()
            return
          }
          if (insidePopup && (event.key === 'Enter' || event.key === ' ')) {
            event.preventDefault()
            this.setOpen(!this.isOpen, 'trigger-press')
            return
          }
          // Typing on the closed trigger of a popup combobox chooses, as a select's does.
          if (!this.isOpen && this.isSingle && event.key.length === 1 && !event.ctrlKey) {
            this.#typeAhead(event.key)
          }
        },
      },
      element: element => {
        this.triggerRef.set(element)
        return buttonType(element)
      },
    }
  })

  #typeAhead(key: string): void {
    const items = this.args.items ? this.flatFilteredItems : []
    const toLabel = this.args.itemToStringLabel
    const current = items.find(item => equal(item, this.value, this.isEqual))
    const next = getNextMatch(items, this.#triggerTypeahead.type(key), current, item =>
      labelOf(item, toLabel),
    )
    if (next !== undefined) this.setSelectedValue(next, 'none')
  }

  clear: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      tabindex: '-1',
      disabled: this.isDisabled,
      'data-test-jn-part': 'clear',
    },
    on: {
      // Focus stays in the input.
      mousedown: event => event.preventDefault(),
      click: () => {
        if (this.isDisabled || this.isReadOnly) return
        this.setInputValue('', 'clear-press')
        this.setSelectedValue(this.isMultiple ? [] : null, 'clear-press')
        this.activeIndex = null
        this.inputRef.current?.focus()
      },
    },
    element: element => {
      this.clearRef.set(element)
      const restoreType = buttonType(element)
      return () => {
        restoreType()
        this.clearRef.release(element)
      }
    },
  }))

  chipsPart: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      // A toolbar keeps NVDA in focus mode while the arrows move between chips.
      role: this.hasValue ? 'toolbar' : undefined,
      'data-test-jn-part': 'chips',
    },
    on: {
      mousedown: event => {
        const target = event.target as Element | null
        if (target !== event.currentTarget && isInteractive(target)) return
        event.preventDefault()
        if (this.isDisabled || this.isReadOnly) return
        this.inputRef.current?.focus()
        this.inputPress(event)
      },
    },
    element: element => {
      this.chipsRef.set(element)
      return () => this.chipsRef.release(element)
    },
  }))

  get chipsElement(): HTMLElement | null {
    return this.chipsRef.value
  }

  /** What the popup is placed against: the trigger when the input is inside it, else the input. */
  get anchorElement(): Element | null {
    return this.inputInsidePopup ? this.triggerRef.value : this.inputRef.value
  }

  /** What counts as inside the popup, for dismissal: the input and the buttons and chips around it. */
  get insideElements(): Array<Element | null> {
    return [
      this.inputRef.value,
      this.triggerRef.value,
      this.clearRef.value,
      this.chipsRef.value,
      this.inputRef.value?.closest('[data-slot="input-group"]') ?? null,
    ]
  }

  popup: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.inputInsidePopup ? this.popupId : undefined,
      role: this.inputInsidePopup ? 'dialog' : 'presentation',
      tabindex: '-1',
      'data-open': this.isOpen,
      'data-closed': !this.isOpen,
      'data-empty': this.isEmpty,
      'data-test-jn-part': 'content',
      'data-test-jn-owner': this.id,
    },
  }))

  list: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.listId,
      role: 'listbox',
      tabindex: '-1',
      'aria-multiselectable': this.isMultiple ? 'true' : undefined,
      'data-empty': this.isEmpty,
      'data-test-jn-part': 'list',
    },
    on: {
      keydown: event => {
        if (event.key !== 'Enter' || this.isDisabled || this.isReadOnly) return
        const item = this.activeItem
        if (!item) return
        event.preventDefault()
        event.stopPropagation()
        item.element.click()
      },
    },
    element: element => {
      this.listRef.set(element)
      // Named as the input is: by its labels, or else its own name or placeholder.
      const input = this.inputRef.current
      const named = element.hasAttribute('aria-label') || element.hasAttribute('aria-labelledby')
      if (!named && input) {
        const labels = [...(input.labels ?? [])].map(label => {
          if (!label.id) label.id = idFor(label, 'label')
          return label.id
        })
        const name =
          input.getAttribute('aria-label') ?? input.getAttribute('placeholder') ?? undefined
        if (labels.length) element.setAttribute('aria-labelledby', labels.join(' '))
        else if (name) element.setAttribute('aria-label', name)
      }
      return () => this.listRef.release(element)
    },
  }))

  groupLabel: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'group-label' },
    element: element => {
      if (!element.id) element.id = idFor(element, 'label')
      const group = element.closest('[role="group"]')
      const labelled = group && !group.hasAttribute('aria-labelledby')
      if (labelled) group.setAttribute('aria-labelledby', element.id)
      return () => {
        if (labelled && group.getAttribute('aria-labelledby') === element.id) {
          group.removeAttribute('aria-labelledby')
        }
      }
    },
  }))

  separator: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'separator' },
  }))

  // ----- Form ------------------------------------------------------------------------------------

  get formValues(): string[] {
    const toValue = this.args.itemToStringValue
    if (this.isMultiple) return this.values.map(value => formValueOf(value, toValue))
    return [formValueOf(this.value, toValue)]
  }

  openWith = (open: boolean): void => this.setOpen(open, 'none')

  <template>
    <div
      id={{this.id}}
      data-test-jn="combobox"
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Input=(component ComboboxInput part=this.input)
          Trigger=(component ComboboxTrigger part=this.trigger)
          Clear=(component ComboboxClear combobox=this)
          Value=(component ComboboxValue combobox=this)
          Content=(component ComboboxContent combobox=this)
          List=(component ComboboxList combobox=this)
          Item=(component ComboboxItem combobox=this)
          Group=(component ComboboxGroup combobox=this)
          GroupLabel=(component ComboboxGroupLabel part=this.groupLabel)
          Collection=ComboboxCollection
          Empty=(component ComboboxEmpty combobox=this)
          Separator=(component ComboboxSeparator part=this.separator)
          chips=this.chipsPart
          Chip=(component ComboboxChip combobox=this)
          input=this.input
          trigger=this.trigger
          clear=this.clear
          chipsElement=this.chipsElement
          value=this.value
          inputValue=this.inputValue
          isOpen=this.isOpen
          setOpen=this.openWith
          setValue=this.setValue
        )
      }}
      {{#if @formName}}
        {{#each this.formValues as |formValue|}}
          <input
            type="hidden"
            name={{@formName}}
            value={{formValue}}
            form={{@form}}
            disabled={{@disabled}}
            data-test-jn-part="form-value"
          />
        {{/each}}
      {{/if}}
      <span hidden {{this.syncInput this.inputValue}}></span>
    </div>
  </template>

  /** Keeps the registered input's text the combobox's, whichever element it is. */
  syncInput = modifier((_element: HTMLElement, [value]: [string]) => {
    const input = this.inputRef.current
    if (input && input.value !== value) input.value = value
  })
}

export default Combobox
