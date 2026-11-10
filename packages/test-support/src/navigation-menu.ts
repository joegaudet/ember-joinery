import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressEscape, pressOutside } from './layers.ts'
import { hover, unhover } from './pointer.ts'
import { pressKey } from './focus.ts'
import { NotFoundError } from './-private/tree.ts'
import { accessibleName, text } from './-private/overlay.ts'

const LINK = '[data-test-jn-part="link"]'

/**
 * The link among `links` whose text is `label`, or else the only one whose text starts with it
 * (a link with a title and a description: `"Introduction"` for "Introduction Re-usable
 * components…"). Throws when there is none, or more than one.
 */
function findLink(links: HTMLElement[], label: string, where: string): HTMLElement {
  const exact = links.find(element => text(element) === label)
  if (exact) return exact
  const starting = links.filter(element => text(element).startsWith(`${label} `))
  if (starting.length === 1) return starting[0]!
  const names = links.map(each => `"${text(each)}"`).join(', ')
  throw new NotFoundError(
    starting.length
      ? `more than one link starts with "${label}" in ${where}`
      : `no link "${label}" in ${where} (there are: ${names})`,
  )
}

/** One item of a navigation menu that opens a content: its trigger, and its content's links. */
export class NavigationMenuItemLevel {
  readonly #trigger: () => HTMLElement

  constructor(trigger: () => HTMLElement) {
    this.#trigger = trigger
  }

  /** Its trigger. */
  get trigger(): HTMLElement {
    return this.#trigger()
  }

  /** Its value (`data-test-jn-value`). */
  get value(): string | null {
    return this.trigger.getAttribute('data-test-jn-value')
  }

  /** Whether its content is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Its content, through the trigger's `aria-controls`, or `null` while it isn't rendered. */
  get content(): HTMLElement | null {
    const id = this.trigger.getAttribute('aria-controls')
    return id ? document.getElementById(id) : null
  }

  /** The content's accessible name: its trigger's text. */
  get label(): string {
    const content = this.content
    return content ? accessibleName(content) : ''
  }

  /** Which way the content is moving (`data-motion`): `from-start`, `to-end`…, or `null`. */
  get motion(): string | null {
    return this.content?.getAttribute('data-motion') ?? null
  }

  /** The content's links, as elements, in order. */
  get linkElements(): HTMLElement[] {
    const content = this.content
    return content ? [...content.querySelectorAll<HTMLElement>(LINK)] : []
  }

  /** Each of the content's links' text. */
  get links(): string[] {
    return this.linkElements.map(text)
  }

  /** The content's link whose text is `label` (or the only one starting with it). */
  link(label: string): HTMLElement {
    return findLink(this.linkElements, label, `the content of "${text(this.trigger)}"`)
  }

  /** Clicks the trigger: it opens the content, or closes it when it is open. */
  async toggle(): Promise<void> {
    await click(this.trigger)
  }

  /** Opens it with a click on the trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }

  /** Closes it with a click on the trigger, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await this.toggle()
  }

  /** Rests the pointer on the trigger, which opens it after the menu's delay. */
  async hover(): Promise<void> {
    await hover(this.trigger)
  }

  /** Moves the pointer off the trigger (downwards, towards the content, unless `side` says). */
  async unhover(side: 'top' | 'right' | 'bottom' | 'left' = 'top'): Promise<void> {
    await unhover(this.trigger, { side })
  }

  /**
   * Toggles it from the keyboard: focus on the trigger, then Enter (or Space), which presses
   * the button, as a browser does (`pressKey` sends only the key's events). Focus stays on the
   * trigger; Tab or ArrowDown goes on into the content.
   */
  async openWithKeyboard(key: 'Enter' | ' ' = 'Enter'): Promise<void> {
    await focus(this.trigger)
    const prevented = await pressKey(key)
    if (!prevented) await click(this.trigger)
  }

  /** Clicks the content's link `label`: it follows it, and closes the content. */
  async select(label: string): Promise<void> {
    await click(this.link(label))
  }
}

/**
 * Drives a `<NavigationMenu>` from `@ember-joinery/ember` or
 * `@ember-joinery/primitives/navigation-menu`. Its items are found by their triggers' text and
 * its links by theirs, and read through ARIA (a trigger's `aria-expanded`, a link's
 * `aria-current`).
 *
 *   const nav = new NavigationMenuHarness()
 *   assert.deepEqual(nav.triggerLabels, ['Getting started', 'Components'])
 *   const start = nav.item('Getting started')
 *   await start.open()
 *   assert.deepEqual(start.links.length, 3)
 *   await nav.item('Components').hover()
 *   assert.strictEqual(nav.openItem, 'Components')
 */
export class NavigationMenuHarness extends Harness {
  static override component = 'navigation-menu'

  /** The `<ul>` of items. */
  get list(): HTMLElement {
    return this.part('list')
  }

  /** Each trigger, in order. */
  get triggers(): HTMLElement[] {
    return this.parts('trigger')
  }

  /** Each trigger's text, in order. */
  get triggerLabels(): string[] {
    return this.triggers.map(text)
  }

  /** The links in the list itself (not in a content), as elements, in order. */
  get listLinkElements(): HTMLElement[] {
    return [...this.list.querySelectorAll<HTMLElement>(LINK)].filter(
      link => !link.closest('[data-test-jn-part="content"]'),
    )
  }

  /** Each of the list's own links' text. */
  get listLinks(): string[] {
    return this.listLinkElements.map(text)
  }

  /** The list's own link whose text is `label`. */
  listLink(label: string): HTMLElement {
    return findLink(this.listLinkElements, label, `${this}`)
  }

  /** The trigger whose text is `label`. Throws when there is none. */
  trigger(label: string): HTMLElement {
    const trigger = this.triggers.find(element => text(element) === label)
    if (!trigger) {
      const names = this.triggerLabels.map(each => `"${each}"`).join(', ')
      throw new NotFoundError(`no trigger "${label}" in ${this} (there are: ${names})`)
    }
    return trigger
  }

  /** The item whose trigger's text is `label`. */
  item(label: string): NavigationMenuItemLevel {
    return new NavigationMenuItemLevel(() => this.trigger(label))
  }

  /** The text of the trigger whose content is open, or `null`. */
  get openItem(): string | null {
    const open = this.triggers.find(trigger => trigger.getAttribute('aria-expanded') === 'true')
    return open ? text(open) : null
  }

  /** Whether a content is open. */
  get isOpen(): boolean {
    return this.openItem !== null
  }

  /** The open item, or `null`. */
  get open(): NavigationMenuItemLevel | null {
    const label = this.openItem
    return label === null ? null : this.item(label)
  }

  /** The viewport, while it is rendered (a content is open), or `null`. */
  get viewport(): HTMLElement | null {
    return this.queryPart('viewport')
  }

  /** The viewport's size, as the open content gives it (`--radix-navigation-menu-viewport-*`). */
  get viewportSize(): { width: number; height: number } | null {
    const viewport = this.viewport
    if (!viewport) return null
    const read = (name: string) =>
      Number.parseFloat(viewport.style.getPropertyValue(`--radix-navigation-menu-viewport-${name}`))
    return { width: read('width'), height: read('height') }
  }

  /** The indicator, while it is rendered, or `null`. */
  get indicator(): HTMLElement | null {
    return this.queryPart('indicator')
  }

  /** The text of the trigger or link that has focus, or `null`. */
  get focused(): string | null {
    const active = document.activeElement
    if (!(active instanceof HTMLElement) || !this.element.contains(active)) return null
    return text(active)
  }

  /** Presses Escape where focus is: it closes the open content. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }

  /** A press outside the menu. */
  async pressOutside(): Promise<void> {
    await pressOutside()
  }
}
