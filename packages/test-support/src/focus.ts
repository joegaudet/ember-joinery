import { blur, focus, settled } from '@ember/test-helpers'

/** The modifier keys held while a key is pressed. */
export interface KeyModifiers {
  shiftKey?: boolean
  ctrlKey?: boolean
  altKey?: boolean
  metaKey?: boolean
}

/** The element that has focus, or `<body>` when nothing does. */
function focused(): Element {
  return document.activeElement ?? document.body
}

/** Dispatches one keyboard event the way a browser does, and returns it. */
function dispatchKey(
  target: Element,
  type: 'keydown' | 'keyup',
  key: string,
  modifiers: KeyModifiers,
): KeyboardEvent {
  const event = new KeyboardEvent(type, {
    key,
    bubbles: true,
    cancelable: true,
    composed: true,
    view: window,
    ...modifiers,
  })
  target.dispatchEvent(event)
  return event
}

/**
 * Presses one key on the focused element (or `<body>`): `keydown`, then `keyup` unless the
 * key moved focus, which then goes to the element focused now. `key` is a `KeyboardEvent#key`
 * value: `'ArrowDown'`, `'Home'`, `'a'`, `' '`. It sends only the key events, so it doesn't
 * type into inputs or click buttons; use `typeIn` and `click` for those.
 *
 *   await focus(harness.item('bold'))
 *   await pressKey('ArrowRight')
 *   assert.dom(harness.item('italic')).isFocused()
 *
 * @returns whether the page called `preventDefault()` on the `keydown`.
 */
export async function pressKey(key: string, modifiers: KeyModifiers = {}): Promise<boolean> {
  const down = dispatchKey(focused(), 'keydown', key, modifiers)
  await settled()
  dispatchKey(focused(), 'keyup', key, modifiers)
  await settled()
  return down.defaultPrevented
}

/**
 * Types each character of `text` as a key press on the focused element, for typeahead: in a
 * menu, a listbox or a select, typing the start of an item's text moves to it.
 *
 *   await typeKeys('ba') // to "Banana"
 *
 * Like `pressKey`, it sends key events only; it doesn't put text into an input (`typeIn` does).
 */
export async function typeKeys(text: string, modifiers: KeyModifiers = {}): Promise<void> {
  for (const character of text) await pressKey(character, modifiers)
}

// ----- The Tab key ---------------------------------------------------------------------------

/**
 * The test runner's own controls, which aren't part of the page under test: QUnit's toolbar
 * and testem's connection frame.
 */
const RUNNER = '#qunit, iframe[src*="/testem/"]'

/** Whether anything about the element or above it keeps it out of the tab order. */
function isHidden(element: Element): boolean {
  if (element.closest('[inert]')) return true
  for (let node: Element | null = element; node; node = node.parentElement) {
    if (node instanceof HTMLElement && node.hidden) return true
    const parent: HTMLElement | null = node.parentElement
    if (parent instanceof HTMLDetailsElement && !parent.open) {
      if (node !== parent.querySelector(':scope > summary')) return true
    }
  }
  const styles = getComputedStyle(element)
  if (styles.visibility === 'hidden' || styles.display === 'none') return true
  // checkVisibility() sees display: none and content-visibility on every ancestor.
  return 'checkVisibility' in element && !element.checkVisibility()
}

/** Whether the browser's Tab key would stop at `element`, apart from radio groups. */
function isTabbable(element: Element): element is HTMLElement {
  if (!(element instanceof HTMLElement)) return false
  if (element.tabIndex < 0) return false
  if (element.matches(':disabled')) return false
  if (element instanceof HTMLInputElement && element.type === 'hidden') return false
  if (
    (element instanceof HTMLAnchorElement || element instanceof HTMLAreaElement) &&
    !element.hasAttribute('href') &&
    !element.hasAttribute('tabindex')
  ) {
    return false
  }
  return !isHidden(element) && !element.closest(RUNNER)
}

/** A native radio button that's in a named group. */
function groupOf(element: HTMLElement): string | undefined {
  if (!(element instanceof HTMLInputElement) || element.type !== 'radio' || !element.name) {
    return undefined
  }
  return `${element.form ? 'form' : 'document'}:${element.name}`
}

/**
 * The elements the Tab key visits in `within` (default: the whole page), in the order a
 * browser visits them: positive `tabindex`es first, lowest first, then the rest in document
 * order. Of each group of native radio buttons, only the checked one is in the order, or every
 * one when none is checked (the browser stops at the first it comes to). The test runner's own
 * controls (QUnit's toolbar, testem's frame) are left out.
 *
 *   assert.deepEqual(tabOrder(form).map(e => e.id), ['name', 'email', 'save'])
 */
export function tabOrder(within: Element = document.body): HTMLElement[] {
  const elements = [...within.querySelectorAll('*')].filter(isTabbable)
  const checked = new Set<string>()
  for (const element of elements) {
    const group = groupOf(element)
    if (group && (element as HTMLInputElement).checked) checked.add(group)
  }
  const inOrder = elements.filter(element => {
    const group = groupOf(element)
    return !group || !checked.has(group) || (element as HTMLInputElement).checked
  })
  const positive = inOrder.filter(element => element.tabIndex > 0)
  positive.sort((a, b) => a.tabIndex - b.tabIndex)
  return [...positive, ...inOrder.filter(element => element.tabIndex === 0)]
}

/** Where the Tab key goes from `current` through `order`; `undefined` past either end. */
function nextInOrder(order: HTMLElement[], current: Element, backward: boolean) {
  const index = order.indexOf(current as HTMLElement)
  if (index !== -1) return order[index + (backward ? -1 : 1)]
  if (current === document.body || current === document.documentElement) {
    return backward ? order.at(-1) : order[0]
  }
  // From an element outside the order (tabindex="-1"), the next one after it in the document.
  const after = (element: Element) =>
    Boolean(current.compareDocumentPosition(element) & Node.DOCUMENT_POSITION_FOLLOWING)
  const sequential = order.filter(element => element.tabIndex === 0)
  if (backward) return sequential.filter(element => !after(element) && element !== current).at(-1)
  return sequential.find(after)
}

/** Focuses as `focus()` from `@ember/test-helpers` does, or directly where it won't (an iframe). */
async function focusOn(element: HTMLElement): Promise<void> {
  try {
    await focus(element)
  } catch {
    element.focus()
    await settled()
  }
}

/**
 * Presses Tab (or Shift+Tab, with `{ shift: true }`) as a browser does: the focused element
 * gets the `keydown`, and unless the page prevents it, focus moves to the next element in the
 * tab order (see `tabOrder`). Past the last element, focus leaves the page, as when the browser
 * moves it to its own toolbar: nothing is focused afterwards. Tests can't press the real Tab
 * key, so this is how they check a focus trap or a roving tab stop.
 *
 *   await tab()
 *   assert.dom(dialog.closeButton).isFocused()
 *   await tab({ shift: true })
 */
export async function tab(options: { shift?: boolean } = {}): Promise<void> {
  const modifiers = { shiftKey: options.shift ?? false }
  const down = dispatchKey(focused(), 'keydown', 'Tab', modifiers)
  await settled()
  if (!down.defaultPrevented) {
    const current = focused()
    const next = nextInOrder(tabOrder(), current, modifiers.shiftKey)
    if (next) await focusOn(next)
    else if (current !== document.body) await blur(current)
  }
  dispatchKey(focused(), 'keyup', 'Tab', modifiers)
  await settled()
}
