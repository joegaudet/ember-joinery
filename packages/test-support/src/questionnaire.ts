import { click, fillIn, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey, type KeyModifiers } from './focus.ts'

function text(element: Element | null | undefined): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** Whether an element shows: neither it nor an ancestor is `hidden`. */
function shown(element: Element): boolean {
  return !element.closest('[hidden]')
}

/** A navigation button, by the part it is. */
export type QuestionnaireButton = 'previous' | 'skip' | 'next' | 'submit'

/**
 * Drives a `<Questionnaire>`, from `@ember-joinery/ember` or, headless, from
 * `@ember-joinery/primitives/questionnaire`. It reads each item by its `@name` (the active one
 * by default): its status, its answers and its error, through the fieldset's and the controls'
 * ARIA and native state; it answers as a reader does, by clicking a choice or typing, and moves
 * with the navigation buttons or the keyboard.
 *
 *   const plan = new QuestionnaireHarness('plan') // <Questionnaire @name="plan">
 *   await plan.choose('tool-calls')
 *   await plan.next()
 *   assert.strictEqual(plan.activeItem, 'signals')
 *   assert.strictEqual(plan.progressText, 'Question 2 of 3')
 */
export class QuestionnaireHarness extends Harness {
  static override component = 'questionnaire'

  /** The `<form>`. */
  get form(): HTMLFormElement {
    return this.element as HTMLFormElement
  }

  /** What the form would submit now. */
  get formData(): FormData {
    return new FormData(this.form)
  }

  /** Each item's `@name`, in document order. */
  get itemNames(): string[] {
    return this.values('item')
  }

  /** An item's `<fieldset>`: the active one by default. Throws when there is none. */
  item(name: string | null = this.activeItem): HTMLFieldSetElement {
    if (name === null) throw new Error(`Joinery harness: ${this} shows no item`)
    return this.part<HTMLFieldSetElement>('item', name)
  }

  /** The name of the item that shows, or `null`. */
  get activeItem(): string | null {
    const active = this.parts('item').find(item => !item.hidden)
    return active?.getAttribute('data-test-jn-value') ?? null
  }

  /** Whether an item is the one that shows. */
  isActive(name: string): boolean {
    return !this.item(name).hidden
  }

  /** An item's status: `unanswered`, `answered` or `skipped`. */
  status(name: string | null = this.activeItem): string | null {
    return this.item(name).getAttribute('data-status')
  }

  /** Whether an item shows as invalid (`aria-invalid` on its fieldset). */
  isInvalid(name: string | null = this.activeItem): boolean {
    return this.item(name).getAttribute('aria-invalid') === 'true'
  }

  /** Whether an item must be answered. */
  isRequired(name: string | null = this.activeItem): boolean {
    return this.item(name).hasAttribute('data-required')
  }

  /** Whether an item takes several answers. */
  isMultiple(name: string | null = this.activeItem): boolean {
    return this.item(name).hasAttribute('data-multiple')
  }

  /** Whether an item is disabled (it doesn't apply). */
  isDisabled(name: string): boolean {
    return this.item(name).disabled
  }

  /** Whether an item, or something in it, has focus. */
  isFocused(name: string | null = this.activeItem): boolean {
    const active = document.activeElement
    return Boolean(active && this.item(name).contains(active))
  }

  /** Whether the item's fieldset itself has focus, as it does after moving to it. */
  isItemFocused(name: string | null = this.activeItem): boolean {
    return document.activeElement === this.item(name)
  }

  #within(name: string | null, part: string): HTMLElement[] {
    const item = this.item(name)
    return this.parts(part).filter(element => item.contains(element))
  }

  /** An item's question. */
  title(name: string | null = this.activeItem): string {
    return text(this.#within(name, 'title')[0])
  }

  /** An item's description, or `''`. */
  description(name: string | null = this.activeItem): string {
    return text(this.#within(name, 'description')[0])
  }

  /** The names its fieldset's `aria-describedby` gives, as a screen reader hears them. */
  describedBy(name: string | null = this.activeItem): string {
    const ids = this.item(name).getAttribute('aria-describedby')?.split(/\s+/) ?? []
    return ids
      .map(id => text(document.getElementById(id)))
      .filter(Boolean)
      .join(' ')
  }

  /** The error an item shows, or `''` while it shows none. */
  error(name: string | null = this.activeItem): string {
    const error = this.#within(name, 'error').find(element => !element.hidden)
    return text(error)
  }

  /** An item's fixed answers' values, in order. */
  choices(name: string | null = this.activeItem): string[] {
    return this.#within(name, 'choice').map(choice => choice.getAttribute('data-test-jn-value')!)
  }

  /** A fixed answer's row (its `<label>`). */
  choice(value: string, name: string | null = this.activeItem): HTMLLabelElement {
    const choice = this.#within(name, 'choice').find(
      element => element.getAttribute('data-test-jn-value') === value,
    )
    if (!choice) throw new Error(`Joinery harness: no choice "${value}" in item "${name}"`)
    return choice as HTMLLabelElement
  }

  /** A fixed answer's radio or checkbox. */
  choiceInput(value: string, name: string | null = this.activeItem): HTMLInputElement {
    return this.choice(value, name).querySelector<HTMLInputElement>(
      '[data-test-jn-part="choice-input"]',
    )!
  }

  /** A fixed answer's text, without its shortcut key. */
  choiceLabel(value: string, name: string | null = this.activeItem): string {
    return text(this.choice(value, name).querySelector('[data-test-jn-part="choice-label"]'))
  }

  /** The values of the fixed answers checked in an item, in order. */
  checked(name: string | null = this.activeItem): string[] {
    return this.choices(name).filter(value => this.choiceInput(value, name).checked)
  }

  /** Whether a fixed answer is checked. */
  isChecked(value: string, name: string | null = this.activeItem): boolean {
    return this.choiceInput(value, name).checked
  }

  /** A fixed answer's shortcut key, or `null` when it shows none. */
  shortcut(value: string, name: string | null = this.activeItem): string | null {
    const key = this.choice(value, name).querySelector<HTMLElement>(
      '[data-test-jn-part="shortcut"]',
    )
    return key && !key.hidden ? text(key) : null
  }

  /** An item's freeform answer, or `null` without one. */
  input(name: string | null = this.activeItem): HTMLInputElement | null {
    return (this.#within(name, 'input')[0] as HTMLInputElement | undefined) ?? null
  }

  /** The progress that shows (one may sit in each item, as in a card's header). */
  get progress(): HTMLElement {
    const progress = this.parts('progress').find(shown)
    if (!progress) throw new Error(`Joinery harness: ${this} shows no progress`)
    return progress
  }

  /** What the progress says to a screen reader: `Question 2 of 3`. */
  get progressText(): string {
    return this.progress.getAttribute('aria-valuetext') ?? ''
  }

  /** The active item's position, from 1. */
  get current(): number {
    return Number(this.form.getAttribute('data-current'))
  }

  /** How many items it steps through. */
  get total(): number {
    return Number(this.form.getAttribute('data-total'))
  }

  /** A navigation button. */
  button(kind: QuestionnaireButton): HTMLButtonElement {
    return this.part<HTMLButtonElement>(kind)
  }

  /** Whether a navigation button shows (each shows only where it applies). */
  isShown(kind: QuestionnaireButton): boolean {
    const button = this.queryPart<HTMLButtonElement>(kind)
    return Boolean(button && shown(button))
  }

  /** Whether Previous shows. */
  get canGoBack(): boolean {
    return this.isShown('previous')
  }

  /** Whether Skip shows. */
  get canSkip(): boolean {
    return this.isShown('skip')
  }

  /** Whether Next shows. */
  get canGoNext(): boolean {
    return this.isShown('next')
  }

  /** Whether Submit shows. */
  get canSubmit(): boolean {
    return this.isShown('submit')
  }

  /** Clicks a fixed answer, as a reader does: checks a radio, toggles a checkbox. */
  async choose(value: string, name: string | null = this.activeItem): Promise<void> {
    await click(this.choiceInput(value, name))
  }

  /** Types into an item's freeform answer, replacing what is there. */
  async fillIn(value: string, name: string | null = this.activeItem): Promise<void> {
    const input = this.input(name)
    if (!input) throw new Error(`Joinery harness: item "${name}" has no freeform answer`)
    await fillIn(input, value)
  }

  /** Clicks Next. */
  async next(): Promise<void> {
    await click(this.button('next'))
  }

  /** Clicks Previous. */
  async previous(): Promise<void> {
    await click(this.button('previous'))
  }

  /** Clicks Skip. */
  async skip(): Promise<void> {
    await click(this.button('skip'))
  }

  /** Clicks Submit. */
  async submit(): Promise<void> {
    await click(this.button('submit'))
  }

  /** Moves focus to a fixed answer's control. */
  async focusChoice(value: string, name: string | null = this.activeItem): Promise<void> {
    await focus(this.choiceInput(value, name))
  }

  /**
   * Presses a key on the focused element, as the questionnaire's keyboard expects it:
   * `ArrowDown`, `ArrowRight`, a shortcut letter, or `Enter` with `{ metaKey: true }`.
   */
  async press(key: string, modifiers?: KeyModifiers): Promise<boolean> {
    return pressKey(key, modifiers)
  }
}
