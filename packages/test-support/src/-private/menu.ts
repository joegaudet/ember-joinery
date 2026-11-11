// What the menu harnesses (dropdown menu, context menu) share: a press as a browser makes one,
// and a menu level (the root content or a submenu's), read through its DOM and ARIA.
import { click, focus, settled } from '@ember/test-helpers'
import { Harness } from '../harness.ts'
import { pressEscape, pressOutside, type PointerOptions } from '../layers.ts'
import { hover } from '../pointer.ts'
import { pressKey } from '../focus.ts'
import { NotFoundError } from './tree.ts'
import { accessibleName, shownInTopLayer, text } from './overlay.ts'

const ITEM = '[role="menuitem"], [role="menuitemcheckbox"], [role="menuitemradio"]'
const MENU = '[role="menu"]'
const FOCUSABLE = 'a[href], button, input, select, textarea, [tabindex], [contenteditable]'

/** Where a pointer event lands: the element's centre, unless a point is given. */
function centre(element: Element): { x: number; y: number } {
  const rect = element.getBoundingClientRect()
  return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 }
}

export interface PressOptions extends PointerOptions {
  /** The button: 0 (the main one, the default) or 2 (the secondary one, a right click). */
  button?: number
  /** Whether Ctrl is held, as a Mac's Ctrl+click for a right click. */
  ctrlKey?: boolean
  /** Where, in the viewport. Default: the element's centre. */
  point?: { x: number; y: number }
}

/**
 * A press as a browser makes one: `pointerdown`, then, unless the page cancelled it, `mousedown`
 * and focus moving to what was pressed; `pointerup`, `mouseup` and, for the main button, `click`
 * (a right click sends `contextmenu` after the `mousedown` instead). A menu's trigger cancels
 * the `pointerdown` that opens it, so focus never lands on the trigger, as in a browser:
 * `click()` from `@ember/test-helpers` would focus it regardless.
 */
export async function pressAsBrowser(target: Element, options: PressOptions = {}): Promise<void> {
  const { button = 0, ctrlKey = false, pointerType = 'mouse' } = options
  const { x, y } = options.point ?? centre(target)
  const init = {
    bubbles: true,
    cancelable: true,
    composed: true,
    view: window,
    clientX: x,
    clientY: y,
    button,
    buttons: button === 2 ? 2 : 1,
    ctrlKey,
  }
  const pointer = { ...init, pointerType, pointerId: 1, isPrimary: true }
  const down = new PointerEvent('pointerdown', pointer)
  target.dispatchEvent(down)
  if (!down.defaultPrevented) {
    const mousedown = new MouseEvent('mousedown', init)
    target.dispatchEvent(mousedown)
    if (!mousedown.defaultPrevented) target.closest<HTMLElement>(FOCUSABLE)?.focus()
  }
  if (button === 2 || ctrlKey) target.dispatchEvent(new MouseEvent('contextmenu', init))
  await settled()
  target.dispatchEvent(new PointerEvent('pointerup', { ...pointer, buttons: 0 }))
  if (!down.defaultPrevented) target.dispatchEvent(new MouseEvent('mouseup', init))
  if (button === 0 && !ctrlKey) target.dispatchEvent(new MouseEvent('click', init))
  await settled()
}

/**
 * An item's label: its text, whitespace collapsed, with its shortcut and its check mark (the
 * item indicator) left out.
 */
export function itemText(item: Element): string {
  let label = ''
  const walk = (node: Node) => {
    for (const child of node.childNodes) {
      if (child.nodeType === Node.TEXT_NODE) label += child.textContent ?? ''
      else if (child instanceof Element) {
        const part = child.getAttribute('data-test-jn-part')
        if (part === 'shortcut' || part === 'item-indicator') continue
        if (child.getAttribute('role') === 'menu') continue
        walk(child)
      }
    }
  }
  walk(item)
  return label.replace(/\s+/g, ' ').trim()
}

/**
 * One level of a menu: its content (the root's, or a submenu's) and its own items, not those of
 * the submenus inside it. Items are found by their text, the shortcut left out.
 */
export class MenuLevel {
  readonly #content: () => HTMLElement | null

  constructor(content: () => HTMLElement | null) {
    this.#content = content
  }

  /** The content, or `null` while it isn't rendered. */
  get content(): HTMLElement | null {
    return this.#content()
  }

  /** Whether the content is showing in the browser's top layer. */
  get isShown(): boolean {
    return shownInTopLayer(this.content)
  }

  /** Its items, in order: plain, checkbox and radio items, and the triggers of its submenus. */
  get itemElements(): HTMLElement[] {
    const content = this.content
    if (!content) return []
    return [...content.querySelectorAll<HTMLElement>(ITEM)].filter(
      item => item.closest(MENU) === content,
    )
  }

  /** Each item's text, in order. */
  get items(): string[] {
    return this.itemElements.map(itemText)
  }

  /** Each label's text, in order. */
  get labels(): string[] {
    return this.#own('[data-test-jn-part="label"]').map(text)
  }

  /** How many separators it has. */
  get separators(): number {
    return this.#own('[role="separator"]').length
  }

  /** The text of the item that has focus, or `null` (focus on the content itself, or elsewhere). */
  get highlighted(): string | null {
    const active = document.activeElement
    const item = this.itemElements.find(element => element === active)
    return item ? itemText(item) : null
  }

  /** The side the content was placed on, after any flip (`data-side`). */
  get side(): string | null {
    return this.content?.getAttribute('data-side') ?? null
  }

  /** The content's alignment along that side (`data-align`). */
  get align(): string | null {
    return this.content?.getAttribute('data-align') ?? null
  }

  /** The item whose text is `label`. Throws when there is none. */
  item(label: string): HTMLElement {
    const item = this.itemElements.find(element => itemText(element) === label)
    if (!item) {
      throw new NotFoundError(
        `no menu item "${label}" (there are: ${this.items.map(each => `"${each}"`).join(', ')})`,
      )
    }
    return item
  }

  /** Whether the item is disabled (`aria-disabled`). */
  isDisabled(label: string): boolean {
    return this.item(label).getAttribute('aria-disabled') === 'true'
  }

  /** Whether a checkbox or radio item is checked (`aria-checked="true"`). */
  isChecked(label: string): boolean {
    return this.item(label).getAttribute('aria-checked') === 'true'
  }

  /** A checkbox or radio item's `aria-checked`: `true`, `false` or `mixed`. */
  checked(label: string): string | null {
    return this.item(label).getAttribute('aria-checked')
  }

  /** The item's role: `menuitem`, `menuitemcheckbox` or `menuitemradio`. */
  role(label: string): string | null {
    return this.item(label).getAttribute('role')
  }

  /** The item's shortcut text, or `null`. */
  shortcut(label: string): string | null {
    const shortcut = this.item(label).querySelector('[data-test-jn-part="shortcut"]')
    return shortcut ? text(shortcut) : null
  }

  /** The item's `data-variant`, such as `destructive`, or `null`. */
  variant(label: string): string | null {
    return this.item(label).getAttribute('data-variant')
  }

  /** Clicks the item: selecting it closes the menu, unless its `@onSelect` prevents that. */
  async select(label: string): Promise<void> {
    await click(this.item(label))
  }

  /** Rests the pointer on the item, which focuses it (and opens a submenu after a moment). */
  async hover(label: string): Promise<void> {
    await hover(this.item(label))
  }

  /** The submenu the item named `label` opens. */
  sub(label: string): SubMenu {
    return new SubMenu(() => this.item(label))
  }

  /** The elements matching `selector` that are this level's own, not a submenu's. */
  #own(selector: string): HTMLElement[] {
    const content = this.content
    if (!content) return []
    return [...content.querySelectorAll<HTMLElement>(selector)].filter(
      element => element.closest(MENU) === content,
    )
  }
}

/** A submenu: its trigger, an item of the menu it is in, and its own content and items. */
export class SubMenu extends MenuLevel {
  readonly #trigger: () => HTMLElement

  constructor(trigger: () => HTMLElement) {
    super(() => {
      const id = trigger().getAttribute('aria-controls')
      return id ? document.getElementById(id) : null
    })
    this.#trigger = trigger
  }

  /** The item that opens it. */
  get trigger(): HTMLElement {
    return this.#trigger()
  }

  /** Whether it is open, from its trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Its accessible name: its trigger's text. */
  get label(): string {
    const content = this.content
    return content ? accessibleName(content) : ''
  }

  /** Opens it as a mouse does: resting on its trigger, which opens it after a moment. */
  async open(): Promise<void> {
    if (!this.isOpen) await hover(this.trigger)
  }

  /** Opens it from the keyboard: focus on its trigger, and the arrow pointing into it. */
  async openWithKeyboard(): Promise<void> {
    await focus(this.trigger)
    const rtl = getComputedStyle(this.trigger).direction === 'rtl'
    await pressKey(rtl ? 'ArrowLeft' : 'ArrowRight')
  }
}

/**
 * What the dropdown and context menu harnesses share: the root content, read as a `MenuLevel`,
 * and the keys and presses that close it.
 */
export abstract class MenuHarness extends Harness {
  readonly #menu = new MenuLevel(() => this.content)

  /** The trigger: the `Trigger` part, or your own element with the `trigger` modifier. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The menu's content, or `null` while it isn't rendered. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** Whether it is open. */
  abstract get isOpen(): boolean

  /** Whether the content is showing in the browser's top layer. */
  get isShown(): boolean {
    return this.#menu.isShown
  }

  /** The content's accessible name (a dropdown menu's trigger names it), or `''`. */
  get label(): string {
    const content = this.content
    return content ? accessibleName(content) : ''
  }

  /** The content's text, whitespace collapsed. */
  get text(): string {
    return text(this.content)
  }

  /** The side the content was placed on, after any flip (`data-side`). */
  get side(): string | null {
    return this.#menu.side
  }

  /** The content's alignment along that side (`data-align`). */
  get align(): string | null {
    return this.#menu.align
  }

  /** The content's items (not its submenus'), as elements, in order. */
  get itemElements(): HTMLElement[] {
    return this.#menu.itemElements
  }

  /** Each item's text, its shortcut left out. */
  get items(): string[] {
    return this.#menu.items
  }

  /** Each label's text. */
  get labels(): string[] {
    return this.#menu.labels
  }

  /** How many separators the content has. */
  get separators(): number {
    return this.#menu.separators
  }

  /** The text of the item that has focus, or `null`. */
  get highlighted(): string | null {
    return this.#menu.highlighted
  }

  /** The item whose text is `label`. */
  item(label: string): HTMLElement {
    return this.#menu.item(label)
  }

  /** Whether the item is disabled. */
  isDisabled(label: string): boolean {
    return this.#menu.isDisabled(label)
  }

  /** Whether a checkbox or radio item is checked. */
  isChecked(label: string): boolean {
    return this.#menu.isChecked(label)
  }

  /** A checkbox or radio item's `aria-checked`: `true`, `false` or `mixed`. */
  checked(label: string): string | null {
    return this.#menu.checked(label)
  }

  /** The item's role. */
  role(label: string): string | null {
    return this.#menu.role(label)
  }

  /** The item's shortcut text, or `null`. */
  shortcut(label: string): string | null {
    return this.#menu.shortcut(label)
  }

  /** The item's `data-variant`, or `null`. */
  variant(label: string): string | null {
    return this.#menu.variant(label)
  }

  /** Clicks the item, which selects it. */
  async select(label: string): Promise<void> {
    await this.#menu.select(label)
  }

  /** Rests the pointer on the item. */
  async hover(label: string): Promise<void> {
    await this.#menu.hover(label)
  }

  /** The submenu the item named `label` opens, with the same members as this harness's menu. */
  sub(label: string): SubMenu {
    return this.#menu.sub(label)
  }

  /** Presses Escape where focus is: it closes the whole menu. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }

  /** A press outside the menu, as a user dismissing it makes. */
  async pressOutside(): Promise<void> {
    await pressOutside()
  }
}
