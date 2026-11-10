import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { isShowing } from './-private/showing.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<TraceLine>` from `@ember-joinery/ember`: one line of a trace. It reads the line's
 * title, description and status, and clicks whatever wraps it (a collapsible's trigger, a link,
 * a dialog's or a sheet's trigger), as a reader would:
 *
 *   const build = new TraceLineHarness('build') // <TraceLine @name="build" @status="running">
 *   assert.true(build.isRunning)
 *   assert.strictEqual(build.title, 'Running pnpm build')
 */
export class TraceLineHarness extends Harness {
  static override component = 'trace-line'

  /** All the text it shows, whitespace collapsed: its title, then its description. */
  get text(): string {
    return text(this.element)
  }

  /** Its title part. Throws when it has none. */
  get titleElement(): HTMLElement {
    return this.part('title')
  }

  /** Its title's text, a hidden note (`sr-only`) included, as a screen reader hears it. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** Its description's text, or `''` without one. */
  get description(): string {
    return text(this.queryPart('description'))
  }

  /** Whether it has a description. */
  get hasDescription(): boolean {
    return this.queryPart('description') !== null
  }

  /** Its icon slots, in order: the action's before the title, an indicator after it. */
  get icons(): HTMLElement[] {
    return this.parts('icon')
  }

  /** Its `@status`: `running`, `error`, `pending`, or `null` for work that is done. */
  get status(): string | null {
    return this.element.getAttribute('data-status')
  }

  /** Whether the work it reports is under way. */
  get isRunning(): boolean {
    return this.status === 'running'
  }

  /** Whether the work it reports failed. */
  get isError(): boolean {
    return this.status === 'error'
  }

  /** Whether the work it reports hasn't started. */
  get isPending(): boolean {
    return this.status === 'pending'
  }

  /**
   * What wraps the line and acts for it: the nearest link or button around it (a
   * `TraceCollapsible`'s trigger, an `<a>`, a dialog's or a sheet's trigger), or `null` for a
   * line on its own, which reads as text.
   */
  get control(): HTMLElement | null {
    return this.element.closest<HTMLElement>('a[href], button')
  }

  /** Whether it is a link: wrapped in an `<a href>`. */
  get isLink(): boolean {
    return this.control instanceof HTMLAnchorElement
  }

  /** Where its link goes, or `null` when it isn't one. */
  get href(): string | null {
    return this.isLink ? this.control!.getAttribute('href') : null
  }

  /** Whether its link opens a new tab (`target="_blank"`). */
  get opensInNewTab(): boolean {
    return this.isLink && this.control!.getAttribute('target') === '_blank'
  }

  /** Clicks what wraps it, as a reader would. Throws for a line on its own. */
  async click(): Promise<void> {
    const control = this.control
    if (!control) throw new Error(`Joinery harness: ${this} isn't wrapped in a link or a button`)
    await click(control)
  }

  /** Moves focus to what wraps it. Throws for a line on its own, which isn't a tab stop. */
  async focus(): Promise<void> {
    const control = this.control
    if (!control) throw new Error(`Joinery harness: ${this} isn't wrapped in a link or a button`)
    await focus(control)
  }
}

/**
 * Drives a `<TraceCollapsible>` from `@ember-joinery/ember`: a trace row that expands. Its state
 * is read from the trigger's `aria-expanded`, so every test also checks what assistive
 * technology hears:
 *
 *   const run = new TraceCollapsibleHarness('node') // <TraceCollapsible @name="node">
 *   await run.open()
 *   assert.strictEqual(run.line.title, 'Ran node --version')
 *   assert.strictEqual(run.text, '$ node --version v24.18.0')
 */
export class TraceCollapsibleHarness extends Harness {
  static override component = 'trace-collapsible'

  /** The button that opens and closes it. */
  get trigger(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('trigger')
  }

  /** The line in its trigger. */
  get line(): TraceLineHarness {
    return new TraceLineHarness({ within: this.trigger })
  }

  /** The chevron after the line, which turns while it is open. */
  get indicator(): HTMLElement {
    return this.part('indicator')
  }

  /** The content's element, which is there (`hidden`, empty) while closed. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** Whether it is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Whether its content shows: open, or still animating out. */
  get isShown(): boolean {
    return isShowing(this.content)
  }

  /** Whether the trigger can't open or close it. */
  get isDisabled(): boolean {
    return this.trigger.disabled
  }

  /** The trigger's accessible name: its line's text (the chevron is hidden). */
  get label(): string {
    return text(this.trigger)
  }

  /** The content's text, whitespace collapsed: `''` while it is closed. */
  get text(): string {
    const content = this.content
    return content.hidden ? '' : text(content)
  }

  /** Whether the trigger names the content in `aria-controls`, as the ARIA pattern asks. */
  get controlsContent(): boolean {
    const content = this.content
    return Boolean(content.id) && this.trigger.getAttribute('aria-controls') === content.id
  }

  /** Clicks the trigger, as a reader does. */
  async toggle(): Promise<void> {
    await click(this.trigger)
  }

  /** Opens it with the trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }

  /** Closes it with the trigger, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await this.toggle()
  }

  /** Moves focus to the trigger. */
  async focus(): Promise<void> {
    await focus(this.trigger)
  }
}

/**
 * Drives a `<Trace>` from `@ember-joinery/ember`: a list of lines. It finds the lines and rows in
 * it, nested ones included, in document order:
 *
 *   const trace = new TraceHarness()
 *   assert.deepEqual(trace.titles, ['Searched for useChat', 'Ran pnpm test'])
 *   await trace.collapsible({ index: 0 }).open()
 */
export class TraceHarness extends Harness {
  static override component = 'trace'

  /** Every line in it, nested ones (in a row's content) included, in document order. */
  get lines(): TraceLineHarness[] {
    return this.findAll(TraceLineHarness)
  }

  /** Each line's title, in order. */
  get titles(): string[] {
    return this.lines.map(line => line.title)
  }

  /** Every row that expands in it, nested ones included, in document order. */
  get collapsibles(): TraceCollapsibleHarness[] {
    return this.findAll(TraceCollapsibleHarness)
  }

  /** A line in it, by `@name` or position. */
  line(options?: string | { name?: string; index?: number }): TraceLineHarness {
    return this.find(TraceLineHarness, options)
  }

  /** A row in it, by `@name` or position. */
  collapsible(options?: string | { name?: string; index?: number }): TraceCollapsibleHarness {
    return this.find(TraceCollapsibleHarness, options)
  }
}
