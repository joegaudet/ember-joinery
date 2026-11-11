import { click, focus, settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { attributes } from './selectors.ts'
import { pressKey, type KeyModifiers } from './focus.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** An element's accessible name: `aria-label`, else `aria-labelledby`'s text, else its text. */
function nameOf(element: Element): string {
  const label = element.getAttribute('aria-label')
  if (label) return label.trim()
  const labelledBy = element.getAttribute('aria-labelledby')
  if (labelledBy) {
    return labelledBy
      .split(/\s+/)
      .map(id => element.ownerDocument.getElementById(id))
      .filter((found): found is HTMLElement => Boolean(found))
      .map(text)
      .join(' ')
  }
  return text(element)
}

/**
 * Drives a `<Tabs>` from `@ember-joinery/ember`, or the primitives' `Tabs`. Its tabs and panels
 * are found by their `@value` (`data-test-jn-value`), and read through ARIA: the selected tab by
 * `aria-selected`, its panel by the tab's `aria-controls`.
 *
 *   const settings = new TabsHarness('settings') // <Tabs @name="settings">
 *   await settings.select('password')
 *   assert.strictEqual(settings.selected, 'password')
 *   assert.strictEqual(settings.panelText, 'Change your password here.')
 *   await settings.press('ArrowLeft')
 *   assert.strictEqual(settings.focused, 'account')
 */
export class TabsHarness extends Harness {
  static override component = 'tabs'

  /** The tab list (`role="tablist"`). */
  get list(): HTMLElement {
    return this.part('list')
  }

  /** Each tab's element, in order. */
  get triggers(): HTMLElement[] {
    return this.parts('trigger')
  }

  /** Each tab's value, in order. */
  get tabValues(): string[] {
    return this.values('trigger')
  }

  /** The tab whose `@value` this is. Throws when there is none. */
  trigger(value: string): HTMLElement {
    return this.part('trigger', value)
  }

  /** The panel whose `@value` this is, shown or not. Throws when there is none. */
  content(value: string): HTMLElement {
    return this.part('content', value)
  }

  /** The value of the selected tab (`aria-selected="true"`), or `null` when none is. */
  get selected(): string | null {
    const tab = this.triggers.find(element => element.getAttribute('aria-selected') === 'true')
    return tab?.getAttribute(attributes.value) ?? null
  }

  /** Whether the tab with this value is selected (`aria-selected`). */
  isSelected(value: string): boolean {
    return this.trigger(value).getAttribute('aria-selected') === 'true'
  }

  /**
   * The panel shown now: the one the selected tab's `aria-controls` names, unless it is
   * `hidden` (or isn't rendered), else `null`.
   */
  get panel(): HTMLElement | null {
    const selected = this.selected
    if (selected === null) return null
    const id = this.trigger(selected).getAttribute('aria-controls')
    const panel = id ? this.element.ownerDocument.getElementById(id) : null
    return panel && !panel.hidden ? panel : null
  }

  /** The text of the panel shown now, whitespace collapsed, or `''` when none is. */
  get panelText(): string {
    const panel = this.panel
    return panel ? text(panel) : ''
  }

  /** Whether the panel for this value is rendered and not `hidden`. */
  isShown(value: string): boolean {
    const panel = this.queryPart('content', value)
    return Boolean(panel && !panel.hidden)
  }

  /** Whether the tab can't be selected: `disabled`, or `aria-disabled="true"` on a link. */
  isDisabled(value: string): boolean {
    const tab = this.trigger(value)
    if (tab instanceof HTMLButtonElement && tab.disabled) return true
    return tab.getAttribute('aria-disabled') === 'true'
  }

  /** Whether the tab is a link tab (an `<a href>`, such as a `LinkTo`). */
  isLink(value: string): boolean {
    const tab = this.trigger(value)
    return tab instanceof HTMLAnchorElement && tab.hasAttribute('href')
  }

  /** A tab's accessible name: its `aria-label`, else `aria-labelledby`'s text, else its text. */
  label(value: string): string {
    return nameOf(this.trigger(value))
  }

  /** The tab list's accessible name: its `aria-label` or `aria-labelledby`, else `''`. */
  get listLabel(): string {
    const list = this.list
    if (!list.hasAttribute('aria-label') && !list.hasAttribute('aria-labelledby')) return ''
    return nameOf(list)
  }

  /** `horizontal` or `vertical`: the tab list's `aria-orientation`. */
  get orientation(): string | null {
    return this.list.getAttribute('aria-orientation')
  }

  /** The styled tab list's `@variant` (`default` or `line`), or `null` on the primitive. */
  get variant(): string | null {
    return this.list.getAttribute('data-variant')
  }

  /** The value of the tab Tab lands on (`tabindex="0"`), or `null` while the list itself does. */
  get tabStop(): string | null {
    const tab = this.triggers.find(element => element.getAttribute('tabindex') === '0')
    return tab?.getAttribute(attributes.value) ?? null
  }

  /** The value of the tab that has focus, or `null` when focus is elsewhere. */
  get focused(): string | null {
    const active = this.element.ownerDocument.activeElement
    const tab = this.triggers.find(element => element === active || element.contains(active))
    return tab?.getAttribute(attributes.value) ?? null
  }

  /**
   * Clicks a tab, as a user selects it. A disabled `<button>` ignores the click, as in a
   * browser (`click()` from `@ember/test-helpers` would throw on one).
   */
  async select(value: string): Promise<void> {
    const tab = this.trigger(value)
    if (tab instanceof HTMLButtonElement && tab.disabled) return settled()
    await click(tab)
  }

  /** Focuses a tab, as a click or the arrow keys would (in `automatic` mode, that selects it). */
  async focus(value: string): Promise<void> {
    await focus(this.trigger(value))
  }

  /** Presses a key on the focused element: `'ArrowRight'`, `'Home'`, `'Enter'`, `' '`. */
  async press(key: string, modifiers?: KeyModifiers): Promise<void> {
    await pressKey(key, modifiers)
  }
}
