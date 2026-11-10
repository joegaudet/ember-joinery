import { click, focus } from '@ember/test-helpers'
import { ButtonHarness } from './button.ts'
import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** The accessible name of a control with no text of its own: its `aria-label`, else its text. */
function label(element: Element | null): string {
  if (!element) return ''
  return element.getAttribute('aria-label')?.trim() || text(element)
}

/**
 * Drives an `<Attachment>` from `@ember-joinery/ember`. It reads the attachment's name, its
 * metadata and its upload state, finds its actions by their labels, and presses its trigger:
 *
 *   const upload = new AttachmentHarness('report') // <Attachment @name="report">
 *   assert.strictEqual(upload.title, 'sales-dashboard.pdf')
 *   assert.strictEqual(upload.state, 'uploading')
 *   await upload.action('Cancel upload').click()
 *   await upload.open() // its trigger
 */
export class AttachmentHarness extends Harness {
  static override component = 'attachment'

  /** Its `@state`: `idle`, `uploading`, `processing`, `error` or `done`. */
  get state(): string | null {
    return this.element.getAttribute('data-state')
  }

  /** Its `@size`: `default`, `sm` or `xs`. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** Its `@orientation`: `horizontal` or `vertical`. */
  get orientation(): string | null {
    return this.element.getAttribute('data-orientation')
  }

  /** Whether it is uploading or processing, the states that shimmer its title. */
  get isBusy(): boolean {
    return this.state === 'uploading' || this.state === 'processing'
  }

  /** Whether its upload failed. */
  get isError(): boolean {
    return this.state === 'error'
  }

  /** Its title's text, whitespace collapsed, or `''` without one. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** Its description's text, whitespace collapsed, or `''` without one. */
  get description(): string {
    return text(this.queryPart('description'))
  }

  /** Its media. Throws when it has none. */
  get media(): HTMLElement {
    return this.part('media')
  }

  /** Its media's `@variant` (`icon` or `image`), or `null` without media. */
  get mediaVariant(): string | null {
    return this.queryPart('media')?.getAttribute('data-variant') ?? null
  }

  /** The image in its media, or `null` without one. */
  get image(): HTMLImageElement | null {
    return this.queryPart('media')?.querySelector('img') ?? null
  }

  /** Its image's `alt`, or `null` without an image. */
  get imageAlt(): string | null {
    return this.image?.getAttribute('alt') ?? null
  }

  /** Its content. Throws when it has none. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** Its title. Throws when it has none. */
  get titleElement(): HTMLElement {
    return this.part('title')
  }

  /** Its description. Throws when it has none. */
  get descriptionElement(): HTMLElement {
    return this.part('description')
  }

  /** The element holding its actions. Throws when it has none. */
  get actionsElement(): HTMLElement {
    return this.part('actions')
  }

  /** A `ButtonHarness` for each of its actions, in order. */
  get actions(): ButtonHarness[] {
    return this.parts('action').map(
      (_, index) => new ButtonHarness({ within: this.actionsElement, index }),
    )
  }

  /** The accessible name of each of its actions, in order. */
  get actionLabels(): string[] {
    return this.parts('action').map(label)
  }

  /** The action whose accessible name (its `aria-label`, else its text) is `name`. Throws when there is none. */
  action(name: string): ButtonHarness {
    const index = this.actionLabels.indexOf(name)
    if (index === -1) {
      throw new Error(
        `Joinery: no action "${name}" in ${this} (its actions: ${this.actionLabels.join(', ') || 'none'})`,
      )
    }
    return this.actions[index]!
  }

  /** Its trigger, the button or link over the whole card. Throws when it has none. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** Whether it has a trigger. */
  get hasTrigger(): boolean {
    return this.queryPart('trigger') !== null
  }

  /** Its trigger's accessible name, or `''` without one. */
  get triggerLabel(): string {
    return label(this.queryPart('trigger'))
  }

  /** Where its trigger links to, or `null` when it is a button (or there is none). */
  get href(): string | null {
    return this.queryPart('trigger')?.getAttribute('href') ?? null
  }

  /** Presses its trigger, as a user clicking the card would. */
  async open(): Promise<void> {
    await click(this.trigger)
  }

  /** Moves focus to its trigger, as tabbing to it would. */
  async focusTrigger(): Promise<void> {
    await focus(this.trigger)
  }
}

/**
 * Drives an `<AttachmentGroup>` from `@ember-joinery/ember`: a row of attachments that scrolls
 * across.
 *
 *   const group = new AttachmentGroupHarness()
 *   assert.deepEqual(group.titles, ['workspace.png', 'desk-reference.jpg'])
 *   assert.true(group.isScrollable)
 */
export class AttachmentGroupHarness extends Harness {
  static override component = 'attachment-group'

  /** An `AttachmentHarness` for each attachment in the row, in order. */
  get attachments(): AttachmentHarness[] {
    return this.findAll(AttachmentHarness)
  }

  /** The title of each attachment, in order. */
  get titles(): string[] {
    return this.attachments.map(attachment => attachment.title)
  }

  /** Whether the row is wider than it shows, so it scrolls across. */
  get isScrollable(): boolean {
    const element = this.element
    return element.scrollWidth > element.clientWidth + 1
  }

  /**
   * How far it is scrolled across, from its start, in pixels: right to left, a positive
   * distance too.
   */
  get scrollOffset(): number {
    return Math.abs(this.element.scrollLeft)
  }
}
