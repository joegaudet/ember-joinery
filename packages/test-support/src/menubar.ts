import { focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressEscape, pressOutside } from './layers.ts'
import { hover } from './pointer.ts'
import { pressKey } from './focus.ts'
import { MenuLevel, pressAsBrowser } from './-private/menu.ts'
import { NotFoundError } from './-private/tree.ts'
import { accessibleName, text } from './-private/overlay.ts'

/**
 * One menu of a menubar: its trigger, in the bar, and its content and items, with a
 * [Dropdown Menu harness's](./dropdown-menu.ts) members for those (`items`, `select()`,
 * `sub()`…). Its content is found through the trigger's `aria-controls`, so it is `null` while
 * the menu is closed.
 */
export class MenubarMenuLevel extends MenuLevel {
  readonly #trigger: () => HTMLElement

  constructor(trigger: () => HTMLElement) {
    super(() => {
      const id = trigger().getAttribute('aria-controls')
      return id ? document.getElementById(id) : null
    })
    this.#trigger = trigger
  }

  /** Its trigger in the menubar. */
  get trigger(): HTMLElement {
    return this.#trigger()
  }

  /** Whether it is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Whether its trigger is disabled. */
  get isTriggerDisabled(): boolean {
    return this.trigger.hasAttribute('data-disabled')
  }

  /** The content's accessible name: its trigger's text. */
  get label(): string {
    const content = this.content
    return content ? accessibleName(content) : ''
  }

  /** The content's text, whitespace collapsed. */
  get text(): string {
    return text(this.content)
  }

  /**
   * Presses the trigger as a pointer does: it opens the menu when it is closed, and closes it
   * when it is open. Focus goes to the content, not an item.
   */
  async toggle(): Promise<void> {
    await pressAsBrowser(this.trigger)
  }

  /** Opens it with a press on its trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }

  /** Closes it with a press on its trigger, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await this.toggle()
  }

  /**
   * Opens it from the keyboard: focus on its trigger, then `key` (Enter, Space or ArrowDown).
   * Focus goes to its first item.
   */
  async openWithKeyboard(key: 'Enter' | ' ' | 'ArrowDown' = 'Enter'): Promise<void> {
    await focus(this.trigger)
    await pressKey(key)
  }

  /** Moves the pointer onto its trigger: while another menu is open, that opens this one. */
  async hoverTrigger(): Promise<void> {
    await hover(this.trigger)
  }
}

/**
 * Drives a `<Menubar>` from `@ember-joinery/ember` or `@ember-joinery/primitives/menubar`. Its
 * menus are found by their triggers' text, and read through ARIA: a trigger's `aria-expanded`
 * says its menu is open, and the items' roles and `aria-checked` what they are.
 *
 *   const menubar = new MenubarHarness()
 *   assert.deepEqual(menubar.menus, ['File', 'Edit', 'View'])
 *   const file = menubar.menu('File')
 *   await file.open()
 *   assert.deepEqual(file.items, ['New Tab', 'New Window', 'Share', 'Print...'])
 *   await pressKey('ArrowRight') // Edit opens
 *   assert.strictEqual(menubar.openMenu, 'Edit')
 *   await menubar.menu('Edit').select('Undo')
 */
export class MenubarHarness extends Harness {
  static override component = 'menubar'

  /** Each menu's trigger, in order. */
  get triggers(): HTMLElement[] {
    return this.parts('trigger')
  }

  /** Each menu's name: its trigger's text, in order. */
  get menus(): string[] {
    return this.triggers.map(text)
  }

  /** The trigger whose text is `label`. Throws when there is none. */
  trigger(label: string): HTMLElement {
    const trigger = this.triggers.find(element => text(element) === label)
    if (!trigger) {
      throw new NotFoundError(
        `no menu "${label}" in ${this} (there are: ${this.menus.map(each => `"${each}"`).join(', ')})`,
      )
    }
    return trigger
  }

  /** The menu whose trigger's text is `label`. */
  menu(label: string): MenubarMenuLevel {
    return new MenubarMenuLevel(() => this.trigger(label))
  }

  /** The name of the menu that is open, or `null`. */
  get openMenu(): string | null {
    const open = this.triggers.find(trigger => trigger.getAttribute('aria-expanded') === 'true')
    return open ? text(open) : null
  }

  /** Whether a menu is open. */
  get isOpen(): boolean {
    return this.openMenu !== null
  }

  /** The name of the menu whose trigger has focus, or `null`. */
  get focusedTrigger(): string | null {
    const active = document.activeElement
    const trigger = this.triggers.find(element => element === active)
    return trigger ? text(trigger) : null
  }

  /** The name of the menu whose trigger Tab lands on (`tabindex="0"`), or `null`. */
  get tabStop(): string | null {
    const trigger = this.triggers.find(element => element.getAttribute('tabindex') === '0')
    return trigger ? text(trigger) : null
  }

  /** Presses Escape where focus is: it closes the open menu. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }

  /** A press outside the menubar and its menus. */
  async pressOutside(): Promise<void> {
    await pressOutside()
  }
}
