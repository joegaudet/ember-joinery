import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import { focusElement, focusable } from './focus.ts'

/** How long a search lasts after its last key, in milliseconds, as in Radix: one second. */
export const TYPEAHEAD_TIMEOUT = 1000

/**
 * Whether a key press types ahead: one printable character, with no Ctrl, Alt or Meta held
 * (Shift is fine, for capitals), as Radix's menus and select read it.
 */
export function isTypeaheadKey(
  event: Pick<KeyboardEvent, 'key' | 'ctrlKey' | 'altKey' | 'metaKey'>,
) {
  return event.key.length === 1 && !event.ctrlKey && !event.altKey && !event.metaKey
}

/** The array, starting at `start` and wrapping round. */
function wrap<T>(array: readonly T[], start: number): T[] {
  return array.map((_, index) => array[(start + index) % array.length]!)
}

/**
 * The item a search moves to, as Radix's menus and select find it: the first item after the
 * current one whose text starts with the search, ignoring case, wrapping round. A search of one
 * repeated letter (`"aaa"`) cycles through the items starting with that letter; a one-letter
 * search never matches the current item, so pressing a letter again moves on. Returns
 * `undefined` when nothing else matches.
 *
 *   getNextMatch(['Apple', 'Banana', 'Blueberry'], 'b', 'Banana') // 'Blueberry'
 *   getNextMatch(options, 'bl', current, option => option.label)
 *
 * @param items the candidates, in order (leave out disabled ones)
 * @param search what has been typed so far
 * @param current the item that is current now, if any
 * @param textOf an item's text (default: the item itself, as a string)
 */
export function getNextMatch<T>(
  items: readonly T[],
  search: string,
  current?: T,
  textOf: (item: T) => string = String,
): T | undefined {
  const isRepeated = search.length > 1 && Array.from(search).every(char => char === search[0])
  const normalized = (isRepeated ? search[0]! : search).toLowerCase()
  const currentIndex = current === undefined ? -1 : items.indexOf(current)
  let candidates = wrap(items, Math.max(currentIndex, 0))
  if (normalized.length === 1) candidates = candidates.filter(item => item !== current)
  const next = candidates.find(item => textOf(item).toLowerCase().startsWith(normalized))
  return next !== current ? next : undefined
}

/**
 * The text typed so far in a typeahead search, as Radix keeps it: each key adds to it, and it
 * clears a second (`timeout`) after the last key.
 *
 *   typeahead = new Typeahead()
 *   onKeyDown = (event) => {
 *     if (!isTypeaheadKey(event)) return
 *     const match = getNextMatch(this.options, this.typeahead.type(event.key), this.current, o => o.label)
 *     if (match) this.highlight(match)
 *   }
 *
 * Call `dispose()` when its owner goes, to stop the timer.
 */
export class Typeahead {
  readonly #timeout: number
  #search = ''
  #timer: ReturnType<typeof setTimeout> | undefined

  constructor(options: { timeout?: number } = {}) {
    this.#timeout = options.timeout ?? TYPEAHEAD_TIMEOUT
  }

  /** What has been typed so far, or `''`. */
  get search(): string {
    return this.#search
  }

  /**
   * Whether a search is under way. While it is, Space is part of the search, not a press of
   * the focused item: a menu item or option shouldn't activate on it.
   */
  get isTyping(): boolean {
    return this.#search !== ''
  }

  /** Adds a key to the search, restarts the timer, and returns the search. */
  type(key: string): string {
    this.#search += key
    clearTimeout(this.#timer)
    this.#timer = setTimeout(() => this.reset(), this.#timeout)
    return this.#search
  }

  /** Clears the search now. */
  reset(): void {
    this.#search = ''
    clearTimeout(this.#timer)
    this.#timer = undefined
  }

  /** Stops the timer. */
  dispose(): void {
    this.reset()
  }
}

/** An element's text for typeahead: its own, with whitespace collapsed. */
function textContentOf(element: HTMLElement): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** Whether an item says it is disabled. */
function isDisabledItem(element: HTMLElement): boolean {
  return element.getAttribute('aria-disabled') === 'true' || element.hasAttribute('data-disabled')
}

interface TypeaheadSignature {
  Element: HTMLElement
  Args: {
    Named: {
      /**
       * The items to search, in order. Default: the focusable elements inside (those with
       * `tabindex="-1"` too), leaving out any with `aria-disabled="true"` or `data-disabled`.
       */
      items?: () => HTMLElement[]
      /** An item's text. Default: its `textContent`, trimmed; give one for icons or extra text. */
      textValue?: (item: HTMLElement) => string
      /** Called with the matching item. Default: focus it. */
      onMatch?: (item: HTMLElement, event: KeyboardEvent) => void
      /** How long a search lasts after its last key. Default one second. */
      timeout?: number
      /** Turn it off. */
      disabled?: boolean
    }
  }
}

/**
 * Typeahead on a container, as in Radix's menus: typing the start of an item's text moves focus
 * to it. Keys add up for a second, so "ba" goes past "Apple" to "Banana", and pressing one
 * letter again moves on to the next item starting with it.
 *
 *   <div role="listbox" aria-label="Fruit" {{typeahead}}>
 *     <div role="option" tabindex="-1">Apple</div>
 *     <div role="option" tabindex="-1">Banana</div>
 *   </div>
 *
 * While a search is under way, Space is part of it. The modifier hears keys before the items
 * do, and prevents that Space, so a button isn't pressed and an item's own Space handler sees
 * `event.defaultPrevented` (a part's listeners skip it on their own, as Radix's do). The search
 * clears when focus leaves the container.
 */
export class typeahead extends Modifier<TypeaheadSignature> {
  #named: TypeaheadSignature['Args']['Named'] = {}
  #typeahead: Typeahead | undefined
  #timeout: number | undefined
  #installed = false

  override modify(element: HTMLElement, _: [], named: TypeaheadSignature['Args']['Named']): void {
    this.#named = named
    if (!this.#typeahead || this.#timeout !== named.timeout) {
      this.#typeahead?.dispose()
      this.#timeout = named.timeout
      this.#typeahead = new Typeahead({ timeout: named.timeout })
    }
    if (!this.#installed) this.#install(element)
  }

  #install(element: HTMLElement): void {
    this.#installed = true
    const onKeyDown = (event: KeyboardEvent) => this.#onKeyDown(event, element)
    const onFocusOut = (event: FocusEvent) => {
      const next = event.relatedTarget
      if (!(next instanceof Node) || !element.contains(next)) this.#typeahead?.reset()
    }
    // Before the items hear the key, so an item's own Space handling sees it prevented.
    element.addEventListener('keydown', onKeyDown, true)
    element.addEventListener('focusout', onFocusOut)
    registerDestructor(this, () => {
      element.removeEventListener('keydown', onKeyDown, true)
      element.removeEventListener('focusout', onFocusOut)
      this.#typeahead?.dispose()
    })
  }

  #onKeyDown(event: KeyboardEvent, element: HTMLElement): void {
    const named = this.#named
    const search = this.#typeahead
    if (named.disabled || !search || !isTypeaheadKey(event)) return
    if (event.key === ' ' && search.isTyping) event.preventDefault()
    // A space on its own starts no search: it presses the focused item.
    if (event.key === ' ' && !search.isTyping) return

    const items =
      named.items?.() ??
      focusable
        .findAll({ container: element, includeProgrammaticallyFocusable: true })
        .filter(item => !isDisabledItem(item))
    const active = document.activeElement
    const current = items.find(item => item === active || item.contains(active))
    const textOf = named.textValue ?? textContentOf
    const match = getNextMatch(items, search.type(event.key), current, textOf)
    if (!match) return
    if (named.onMatch) named.onMatch(match, event)
    else focusElement(match)
  }
}
