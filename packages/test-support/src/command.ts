import { click, fillIn, focus, settled, triggerEvent } from '@ember/test-helpers'
import { DialogHarness } from './dialog.ts'
import { pressKey, type KeyModifiers } from './focus.ts'
import { Harness } from './harness.ts'
import { attributes } from './selectors.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** Where an item shows: its `aria-posinset` while a search ranks the items, else its place. */
function position(element: Element, index: number): number {
  const posinset = element.getAttribute('aria-posinset')
  return posinset === null ? index : Number(posinset)
}

/**
 * Drives a `<Command>` from `@ember-joinery/ember`, or the primitives' `Command`: the search
 * box, the items it shows (in the order a search ranks them), the selected item, and the keys.
 * It reads state through ARIA: the items are `role="option"` with `aria-selected` and
 * `aria-disabled`, and the input names the selected one in `aria-activedescendant`.
 *
 *   const command = new CommandHarness()
 *   await command.search('cal')
 *   assert.deepEqual(command.itemValues, ['Calendar', 'Calculator'])
 *   await command.press('ArrowDown')
 *   assert.strictEqual(command.selected, 'Calculator')
 *   await command.press('Enter') // chooses it
 */
export class CommandHarness extends Harness {
  static override component = 'command'

  /** The search box. */
  get input(): HTMLInputElement {
    return this.part<HTMLInputElement>('input')
  }

  /** The list the items show in. */
  get list(): HTMLElement {
    return this.part('list')
  }

  /** The items it shows, in the order they show. */
  get items(): HTMLElement[] {
    return this.parts('item')
      .map((element, index) => [element, position(element, index)] as const)
      .sort((a, b) => a[1] - b[1])
      .map(([element]) => element)
  }

  /** Each shown item's value (its `@value`, or its text), in the order they show. */
  get itemValues(): string[] {
    return this.items.map(item => item.getAttribute(attributes.value) ?? '')
  }

  /** Each shown item's text, in the order they show. */
  get texts(): string[] {
    return this.items.map(text)
  }

  /** The item with this value. Throws when it isn't shown. */
  item(value: string): HTMLElement {
    return this.part('item', value)
  }

  /** Whether an item with this value is shown. */
  hasItem(value: string): boolean {
    return this.queryPart('item', value) !== null
  }

  /** The selected item's value (`aria-selected`), or `null`. */
  get selected(): string | null {
    const item = this.items.find(element => element.getAttribute('aria-selected') === 'true')
    return item?.getAttribute(attributes.value) ?? null
  }

  /** The item the input names in `aria-activedescendant`, or `null`. */
  get activeItem(): HTMLElement | null {
    const id = this.input.getAttribute('aria-activedescendant')
    return id ? (this.items.find(item => item.id === id) ?? null) : null
  }

  /** Whether the item with this value is selected. */
  isSelected(value: string): boolean {
    return this.item(value).getAttribute('aria-selected') === 'true'
  }

  /** Whether the item with this value is disabled (`aria-disabled`). */
  isDisabled(value: string): boolean {
    return this.item(value).getAttribute('aria-disabled') === 'true'
  }

  /** The groups shown (a search hides those it leaves nothing in), in the order they show. */
  get groups(): HTMLElement[] {
    return this.parts('group')
      .filter(group => !group.hidden)
      .map((element, index) => [element, Number(element.style.order) || 0, index] as const)
      .sort((a, b) => a[1] - b[1] || a[2] - b[2])
      .map(([element]) => element)
  }

  /** The headings of the groups shown, in the order they show. */
  get headings(): string[] {
    return this.groups.map(group => group.getAttribute(attributes.value) ?? '')
  }

  /** The values of the items shown in the group with this heading. */
  groupValues(heading: string): string[] {
    const group = this.parts('group').find(
      element => element.getAttribute(attributes.value) === heading,
    )
    if (!group) return []
    return this.itemValues.filter(value => group.contains(this.item(value)))
  }

  /** The separators shown: none during a search, unless they `@alwaysRender`. */
  get separators(): HTMLElement[] {
    return this.parts('separator')
  }

  /** What shows when nothing matches, or `null` while something does. */
  get empty(): HTMLElement | null {
    return this.queryPart('empty')
  }

  /** Whether nothing matches the search. */
  get isEmpty(): boolean {
    return this.empty !== null
  }

  /** What `role="status"` says for screen readers: `3 results`. */
  get status(): string {
    return text(this.part('status'))
  }

  /** The text in the search box. */
  get query(): string {
    return this.input.value
  }

  /** Whether focus is in the search box. */
  get hasFocus(): boolean {
    return this.input.ownerDocument.activeElement === this.input
  }

  /** Types a search, replacing what was there, as a user typing it would. */
  async search(query: string): Promise<void> {
    await fillIn(this.input, query)
  }

  /** Empties the search box. */
  async clear(): Promise<void> {
    await fillIn(this.input, '')
  }

  /**
   * Presses a key in the search box (focusing it first): `'ArrowDown'`, `'Enter'`, `'n'` with
   * `{ ctrlKey: true }`.
   */
  async press(key: string, modifiers?: KeyModifiers): Promise<void> {
    if (!this.hasFocus) await focus(this.input)
    await pressKey(key, modifiers)
  }

  /** Moves the pointer over an item, which selects it. */
  async hover(value: string): Promise<void> {
    await triggerEvent(this.item(value), 'pointermove')
  }

  /** Chooses an item with a click. */
  async choose(value: string): Promise<void> {
    await click(this.item(value))
  }
}

/**
 * Drives a `<CommandDialog>`: a `DialogHarness` (open or not, its title, Escape, a press
 * outside) with the `<Command>` inside it as `command`.
 *
 *   const palette = new CommandDialogHarness()
 *   await palette.pressHotkey('mod+k')
 *   assert.true(palette.isOpen)
 *   await palette.command.search('settings')
 */
export class CommandDialogHarness extends DialogHarness {
  static override component: string | readonly string[] = 'command-dialog'

  /** The command menu inside it, while it is open. */
  get command(): CommandHarness {
    return this.child(CommandHarness)
  }

  /**
   * Presses a hotkey as the browser would, on whatever has focus: `"mod+k"`, where `mod` is ⌘
   * on a Mac and Ctrl elsewhere, as `@hotkey` reads it.
   */
  async pressHotkey(hotkey: string): Promise<void> {
    const parts = hotkey.split('+').map(part => part.trim().toLowerCase())
    const key = parts.pop() ?? ''
    // As `isMac()` in @ember-joinery/primitives/keys decides it.
    const nav = navigator as Navigator & { userAgentData?: { platform?: string } }
    const mac =
      /mac|ios/i.test(nav.userAgentData?.platform ?? '') ||
      /Mac OS|Macintosh|iPhone|iPad/.test(nav.userAgent)
    const has = (name: string) => parts.includes(name)
    const modifiers: KeyModifiers = {
      metaKey: has('meta') || (has('mod') && mac),
      ctrlKey: has('ctrl') || (has('mod') && !mac),
      altKey: has('alt'),
      shiftKey: has('shift'),
    }
    await pressKey(key, modifiers)
    await settled()
  }
}
