// A port of shadcn-ui/ui `packages/react/src/questionnaire` (@shadcn/react's headless
// Questionnaire, MIT): `use-questionnaire-root.ts`, `use-questionnaire-item.ts`,
// `use-questionnaire-choice.ts`, `use-questionnaire-input.ts` and `components.tsx`, as state
// classes whose parts `part()` puts on any element, so the headless components and the styled
// ones in `@ember-joinery/ember` render the same thing.
import { tracked } from '@glimmer/tracking'
import { isDestroyed, isDestroying } from '@ember/destroyable'
import { renderSettled } from '@ember/renderer'
import { buildWaiter } from '@ember/test-waiters'
import { isDevelopingApp, macroCondition } from '@embroider/macros'
import Modifier from 'ember-modifier'
import { ControllableState } from '../controllable-state.ts'
import { getDirection } from '../direction.gts'
import { idFor } from '../id.ts'
import { part, type PartModifier, type PartSpec } from '../part.ts'
import {
  answerKeyShortcuts,
  byDocumentOrder,
  collectionDefinitionWarnings,
  collectionRegistrationWarnings,
  hasInputValue,
  initialItemName,
  isRadioTarget,
  isTextEntryTarget,
  shortcutFromKey,
  shortcutKeys,
  shortcutsByChoiceValue,
  type QuestionnaireItemDefinition,
  type QuestionnaireItemRegistration,
  type QuestionnaireItemStatus,
  type QuestionnaireShortcutMode,
} from './utils.ts'

const waiter = buildWaiter('@ember-joinery/primitives:questionnaire')

/** A controlled input whose selection hasn't been put in step with its value yet. */
const NOT_SYNCED = Symbol('not synced')

/**
 * Runs `callback` once the current render is over, holding the test waiter till then, unless
 * `owner` has gone. Registration happens while rendering, and the change it makes is read by
 * the same render, so it shows in a render of its own, right after.
 */
function afterRender(owner: object, callback: () => void): void {
  const token = waiter.beginAsync()
  queueMicrotask(() => {
    try {
      if (!isDestroying(owner) && !isDestroyed(owner)) callback()
    } finally {
      waiter.endAsync(token)
    }
  })
}

/** The state a navigation button renders: upstream's `QuestionnaireNavigationState`. */
export interface QuestionnaireNavigationOptions {
  /** Whether it is disabled (the caller's choice: it never disables itself). */
  disabled?: boolean
}

/** Where a `QuestionnaireState` reads its settings. Each is a function, so it reads them live. */
export interface QuestionnaireOptions {
  /** The collection of items, for progress, the actions and the shortcuts from the first render. */
  items?: () => readonly QuestionnaireItemDefinition[] | undefined
  /** The active item, when the caller controls it. */
  item?: () => string | undefined
  /** The item it starts on, when uncontrolled. Default the first enabled item. */
  defaultItem?: () => string | undefined
  /** Called with the name of each item it moves to. */
  onItemChange?: () => ((item: string) => void) | undefined
  /** The keys that pick a fixed answer. */
  shortcuts?: () => QuestionnaireShortcutMode | undefined
  /** `false` turns on the browser's own validation of filled answers. Default `true`. */
  noValidate?: () => boolean | undefined
  /** Called when every item is valid and the form submits. */
  onSubmit?: () => ((event: SubmitEvent) => void) | undefined
  /** Called when the form resets, before the answers go back to their defaults. */
  onReset?: () => ((event: Event) => void) | undefined
}

interface PendingFocus {
  name: string
  target: 'item' | 'invalid'
}

/**
 * A questionnaire's state and behaviour, as `@shadcn/react`'s Questionnaire has them: the
 * ordered items, the active one, progress, validation, navigation and its keyboard. The root
 * is a native `<form>`, and answers are read with `FormData`.
 *
 *   questionnaire = new QuestionnaireState(this, {
 *     items: () => this.args.items,
 *     onSubmit: () => this.args.onSubmit,
 *   })
 *   <form {{this.questionnaire.root}} {{this.questionnaire.focusEffect this.questionnaire.activeName}}>
 */
export class QuestionnaireState {
  readonly #owner: object
  readonly #options: QuestionnaireOptions
  readonly #items = new Set<QuestionnaireItemState>()
  /** Bumped after items come or go, so what depends on them renders again. */
  @tracked revision = 0
  /**
   * The first item, taken without a word while the state, uncontrolled, has named none of its
   * own yet (no `@items` and no `@defaultItem`, before the items render), as upstream does.
   */
  @tracked private settledOn: string | null = null
  #bumping = false
  #pendingFocus: PendingFocus | null = null
  #lastActive: string | null | undefined = undefined
  /** The development warnings last logged, so each is logged once while it holds. */
  #warned = new Set<string>()
  /** The form, once rendered. */
  element: HTMLFormElement | null = null

  /** The active item's name, controlled (`@item`) or the questionnaire's own. */
  readonly active: ControllableState<string | null>

  /** Put it on the `<form>`: its listeners and state attributes. */
  readonly root: PartModifier<HTMLFormElement>
  /** Put it on the progress element. */
  readonly progress: PartModifier
  /** The navigation buttons' parts. */
  readonly previous: PartModifier<HTMLButtonElement, QuestionnaireNavigationOptions>
  readonly skip: PartModifier<HTMLButtonElement, QuestionnaireNavigationOptions>
  readonly next: PartModifier<HTMLButtonElement, QuestionnaireNavigationOptions>
  readonly submit: PartModifier<HTMLButtonElement, QuestionnaireNavigationOptions>
  /**
   * Put it on the form with the active item's name (`{{q.focusEffect q.activeName}}`): after
   * the questionnaire moves, it focuses the item it moved to (or, when it moved to report an
   * invalid one, that item's first answer), as upstream's layout effect does. In development,
   * it also warns where `@items` and the rendered items part, as upstream's effect does.
   */
  readonly focusEffect: typeof Modifier<{
    Element: HTMLElement
    Args: { Positional: [string | null] }
  }>

  constructor(owner: object, options: QuestionnaireOptions = {}) {
    this.#owner = owner
    this.#options = options
    this.active = new ControllableState<string | null>({
      name: 'item',
      value: () => options.item?.(),
      defaultValue: () => initialItemName(options.items?.(), options.defaultItem?.()),
      onChange: () => options.onItemChange?.() as ((item: string | null) => void) | undefined,
      fallback: null,
    })
    this.root = part<HTMLFormElement>(() => this.rootSpec())
    this.progress = part(() => this.progressSpec())
    this.previous = part<HTMLButtonElement, QuestionnaireNavigationOptions>(named =>
      this.navigationSpec('previous', named),
    )
    this.skip = part<HTMLButtonElement, QuestionnaireNavigationOptions>(named =>
      this.navigationSpec('skip', named),
    )
    this.next = part<HTMLButtonElement, QuestionnaireNavigationOptions>(named =>
      this.navigationSpec('next', named),
    )
    this.submit = part<HTMLButtonElement, QuestionnaireNavigationOptions>(named =>
      this.navigationSpec('submit', named),
    )
    // eslint-disable-next-line @typescript-eslint/no-this-alias -- the modifier's class reads it
    const questionnaire = this
    this.focusEffect = class FocusEffect extends Modifier<{
      Element: HTMLElement
      Args: { Positional: [string | null] }
    }> {
      override modify(_element: HTMLElement, [name]: [string | null]): void {
        questionnaire.#warnAboutCollection()
        questionnaire.#afterActiveRendered(name)
      }
    }
  }

  // ----- Settings ----------------------------------------------------------------------------

  /** The collection given as `@items`, if any. */
  get definitions(): readonly QuestionnaireItemDefinition[] | undefined {
    return this.#options.items?.()
  }

  /** The definition of a named item, from `@items`. */
  definition(name: string): QuestionnaireItemDefinition | undefined {
    return this.definitions?.find(item => item.name === name)
  }

  /** The shortcut mode, or `null` for none. */
  get shortcuts(): QuestionnaireShortcutMode | null {
    return this.#options.shortcuts?.() ?? null
  }

  /** Whether the browser's own validation checks filled answers (`@noValidate={{false}}`). */
  get nativeValidation(): boolean {
    return this.#options.noValidate?.() === false
  }

  // ----- Items -------------------------------------------------------------------------------

  /** @internal An item comes; the returned function is for when it goes. */
  register(item: QuestionnaireItemState): () => void {
    this.#items.add(item)
    this.bump()
    return () => {
      this.#items.delete(item)
      this.bump()
    }
  }

  /** @internal Re-renders what depends on the items, after the render that changed them. */
  bump(): void {
    if (this.#bumping) return
    this.#bumping = true
    afterRender(this.#owner, () => {
      this.#bumping = false
      this.revision += 1
    })
  }

  /** The rendered items that aren't disabled, in document order. */
  get runtimeItems(): QuestionnaireItemState[] {
    void this.revision
    return [...this.#items].filter(item => !item.disabled).sort(byDocumentOrder)
  }

  /** The rendered item with a name, unless it is disabled. */
  itemNamed(name: string | null): QuestionnaireItemState | null {
    if (name === null) return null
    return this.runtimeItems.find(item => item.name === name) ?? null
  }

  /** The names of the items it steps through, in order: `@items`' enabled ones, or the rendered. */
  get names(): string[] {
    const definitions = this.definitions
    if (definitions) return definitions.filter(item => !item.disabled).map(item => item.name)
    return this.runtimeItems.map(item => item.name)
  }

  /** The rendered items it steps through, in the collection's order. */
  get orderedItems(): QuestionnaireItemState[] {
    const definitions = this.definitions
    if (!definitions) return this.runtimeItems
    return this.names.flatMap(name => {
      const item = this.itemNamed(name)
      return item ? [item] : []
    })
  }

  /**
   * The active item's name. Where the state names no item it steps through (nothing yet, an
   * unknown one, or one that is now disabled), the first stands in for the render, and then
   * the questionnaire moves to it (see `#moveToFirst`).
   */
  get activeName(): string | null {
    const name = this.#held
    const names = this.names
    if (!names.length) return name
    return name !== null && names.includes(name) ? name : names[0]!
  }

  /** The name the state holds: `@item`, the questionnaire's own, or the first it settled on. */
  get #held(): string | null {
    const name = this.active.value
    return name === null && !this.active.isControlled ? this.settledOn : name
  }

  /**
   * Where the state names an item it doesn't step through, moves to the first, as upstream's
   * layout effect does: without a word while it has named none of its own, else as `setItem`
   * would, so `@onItemChange` hears it (a host that controls `@item` gets the first) and the
   * item takes focus once it shows.
   */
  #moveToFirst(): void {
    const names = this.names
    const first = names[0]
    const held = this.#held
    if (first === undefined || (held !== null && names.includes(held))) return
    if (held === null && !this.active.isControlled) {
      this.settledOn = first
      return
    }
    this.#pendingFocus = { name: first, target: 'item' }
    this.active.set(first)
  }

  /** The active item's position from 0, or -1 with none. */
  get index(): number {
    const name = this.activeName
    return name === null ? -1 : this.names.indexOf(name)
  }

  /** How many items it steps through. */
  get total(): number {
    return this.names.length
  }

  /** The active item's position from 1, or 0 with none. */
  get current(): number {
    const index = this.index
    return index < 0 ? 0 : index + 1
  }

  /** Whether the active item is the first. */
  get first(): boolean {
    return this.total > 0 && this.index === 0
  }

  /** Whether the active item is the last. */
  get last(): boolean {
    return this.total > 0 && this.index === this.total - 1
  }

  /** The active item, once it has rendered. */
  get activeItem(): QuestionnaireItemState | null {
    return this.index < 0 ? null : this.itemNamed(this.activeName)
  }

  /** Whether the active item must be answered, or `null` with none. */
  get activeRequired(): boolean | null {
    if (this.index < 0) return null
    const definition = this.definition(this.activeName!)
    return definition ? Boolean(definition.required) : (this.activeItem?.required ?? false)
  }

  /** The active item's status, or `null` with none. */
  get activeStatus(): QuestionnaireItemStatus | null {
    if (this.index < 0) return null
    return this.activeItem?.status ?? 'unanswered'
  }

  // ----- Navigation --------------------------------------------------------------------------

  /** Moves to a named item, focusing it (or its first answer) once it shows. */
  setItem = (name: string, target: PendingFocus['target'] = 'item'): void => {
    if (name === this.activeName) return
    this.#pendingFocus = { name, target }
    this.active.set(name)
  }

  /** Moves to the item before the active one. */
  goPrevious = (): void => {
    const index = this.index
    if (index <= 0) return
    this.setItem(this.names[index - 1]!)
  }

  /** Moves to the next item, once the active one is valid. */
  goNext = (): void => {
    const item = this.activeItem
    const index = this.index
    if (!item || index >= this.total - 1) return
    if (!item.validate()) {
      item.focusInvalid()
      return
    }
    this.setItem(this.names[index + 1]!)
  }

  /** Confirms the active item: moves on, or on the last, submits. */
  confirm = (): void => {
    const item = this.activeItem
    if (!item) return
    if (!item.validate()) {
      item.focusInvalid()
      return
    }
    if (this.last) {
      this.element?.requestSubmit()
      return
    }
    this.setItem(this.names[this.index + 1]!)
  }

  /** Skips the active item, unless it is required, and moves on (or submits). */
  skipCurrent = (): void => {
    const item = this.activeItem
    if (!item || item.required) return
    item.skip()
    if (!this.last) {
      this.setItem(this.names[this.index + 1]!)
      return
    }
    // Once the skip has rendered: a skipped item's answers lose their `name` then.
    const token = waiter.beginAsync()
    void renderSettled().then(() => {
      try {
        if (!isDestroying(this.#owner) && !isDestroyed(this.#owner)) this.element?.requestSubmit()
      } finally {
        waiter.endAsync(token)
      }
    })
  }

  /**
   * After a render with a new active item: focus it, as upstream's layout effect. Where the
   * first only stands in for the item the state holds, move to it first (`#moveToFirst`).
   */
  #afterActiveRendered(name: string | null): void {
    // Read here, so the effect runs again once the state holds the first, which it already shows.
    const held = this.#held
    const previous = this.#lastActive
    this.#lastActive = name
    if (name !== null && held !== name) {
      afterRender(this.#owner, () => this.#moveToFirst())
      return
    }
    if (previous === undefined) return
    const pending = this.#pendingFocus
    if (pending && pending.name === name) {
      this.#pendingFocus = null
      afterRender(this.#owner, () => {
        const item = this.itemNamed(name)
        if (pending.target === 'invalid') item?.focusInvalid()
        else item?.focus()
      })
      return
    }
    if (this.active.isControlled && previous !== name) {
      this.#pendingFocus = null
      afterRender(this.#owner, () => this.itemNamed(name)?.focus())
    }
  }

  // ----- Development warnings ----------------------------------------------------------------

  /** The rendered items, disabled ones too, in document order, as upstream registers them. */
  get registrations(): QuestionnaireItemRegistration[] {
    void this.revision
    return [...this.#items].sort(byDocumentOrder).map(item => ({
      name: item.name,
      disabled: item.disabled,
      required: item.required,
      choices: item.controls
        .filter(answer => answer instanceof QuestionnaireChoiceState)
        .map(choice => ({ value: choice.value, disabled: choice.ownDisabled })),
    }))
  }

  /**
   * Where `@items` (and `@defaultItem`) and the rendered items part: duplicate names, an unknown
   * `@defaultItem`, an item or a choice on one side only, and shortcuts that won't match.
   * None without `@items`.
   */
  get collectionWarnings(): string[] {
    const definitions = this.definitions
    if (!definitions) return []
    return [
      ...collectionDefinitionWarnings(definitions, this.#options.defaultItem?.()),
      ...collectionRegistrationWarnings(definitions, this.registrations, this.shortcuts),
    ]
  }

  /**
   * In development, logs each new collection warning with `console.warn` (`[Questionnaire] …`),
   * as upstream does outside production: Ember's `warn()` is silent wherever an app loads
   * Ember's production build of `@ember/debug`, so it isn't used. It reads them now, so the
   * effect that calls it runs again when they could change, and logs them once the render (and
   * the items' registration) is over, as upstream's microtask does. Production builds leave it
   * out (`isDevelopingApp()`).
   */
  #warnAboutCollection(): void {
    if (macroCondition(isDevelopingApp())) {
      void this.collectionWarnings
      afterRender(this.#owner, () => {
        const warnings = new Set(this.element ? this.collectionWarnings : [])
        for (const warning of warnings) {
          if (this.#warned.has(warning)) continue
          console.warn(`[Questionnaire] ${warning}`)
        }
        this.#warned = warnings
      })
    }
  }

  // ----- The form ----------------------------------------------------------------------------

  #handleSubmit = (event: SubmitEvent): void => {
    const invalid = this.orderedItems.find(item => !item.validate())
    if (invalid) {
      event.preventDefault()
      if (invalid.name === this.activeName) {
        invalid.focusInvalid()
        this.#pendingFocus = null
      } else {
        this.setItem(invalid.name, 'invalid')
      }
      return
    }
    this.#options.onSubmit?.()?.(event)
  }

  #handleReset = (event: Event): void => {
    this.#options.onReset?.()?.(event)
    if (event.defaultPrevented) return
    for (const item of this.#items) item.reset()
    const definitions = this.definitions
    const defaultItem = this.#options.defaultItem?.()
    const name = definitions
      ? initialItemName(definitions, defaultItem)
      : (this.runtimeItems.find(item => item.name === defaultItem)?.name ??
        this.runtimeItems[0]?.name)
    if (name) this.setItem(name)
  }

  #handleKeyDown = (event: KeyboardEvent): void => {
    const item = this.activeItem
    const target = event.target
    if (event.defaultPrevented || event.isComposing || event.keyCode === 229) return
    if (!item || !(target instanceof Element)) return

    if (
      event.key === 'Enter' &&
      (event.metaKey || event.ctrlKey) &&
      !event.altKey &&
      !event.shiftKey
    ) {
      event.preventDefault()
      if (!event.repeat) this.confirm()
      return
    }
    if (event.metaKey || event.ctrlKey || event.altKey) return

    if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      if (item.moveAnswerFocus(target, event.key === 'ArrowDown' ? 'next' : 'previous')) {
        event.preventDefault()
        return
      }
    }

    if (
      (event.key === 'ArrowLeft' || event.key === 'ArrowRight') &&
      !isTextEntryTarget(target) &&
      !isRadioTarget(target)
    ) {
      event.preventDefault()
      if (event.repeat) return
      // The arrow that points back goes back: left, or right to left, right.
      const back = getDirection(target) === 'rtl' ? 'ArrowRight' : 'ArrowLeft'
      if (event.key === back) this.goPrevious()
      else if (item.status !== 'unanswered') this.goNext()
      return
    }

    if (event.key === 'Enter') {
      const answer = item.answerByElement(target)
      if (!answer) return
      event.preventDefault()
      if (!event.repeat && answer.isAnswerFilled) this.confirm()
      return
    }

    const shortcuts = this.shortcuts
    if (!shortcuts || isTextEntryTarget(target)) return
    const shortcut = shortcutFromKey(event.key, shortcuts)
    const answer = shortcut ? item.answerByShortcut(shortcut) : null
    if (!answer) return
    event.preventDefault()
    if (event.repeat) return
    answer.element?.focus()
    if (answer instanceof QuestionnaireChoiceState) answer.element?.click()
  }

  /** The `aria-keyshortcuts` names of the keys that go back and forward, in this direction. */
  arrowKeys(element: Element | null): { back: string; forward: string } {
    return getDirection(element) === 'rtl'
      ? { back: 'ArrowRight', forward: 'ArrowLeft' }
      : { back: 'ArrowLeft', forward: 'ArrowRight' }
  }

  /** What the form renders: its state, as upstream's `data-*`, and its listeners. */
  rootSpec(): PartSpec<HTMLFormElement> {
    return {
      attributes: {
        novalidate: !this.nativeValidation,
        'data-shortcuts': this.shortcuts,
        'data-current': this.current,
        'data-total': this.total,
        'data-first': this.first,
        'data-last': this.last,
      },
      on: {
        keydown: this.#handleKeyDown,
        submit: this.#handleSubmit as (event: Event) => void,
        reset: this.#handleReset,
      },
      element: element => {
        this.element = element
        return () => {
          if (this.element === element) this.element = null
        }
      },
    }
  }

  /** The words a screen reader hears for the progress: `Question 2 of 3`. */
  progressText(format?: (current: number, total: number) => string): string | undefined {
    if (!this.total) return undefined
    return (format ?? ((current, total) => `Question ${current} of ${total}`))(
      this.current,
      this.total,
    )
  }

  /** What the progress element renders: a named, live progressbar. */
  progressSpec(): PartSpec {
    const total = this.total
    return {
      attributes: {
        role: 'progressbar',
        'aria-live': 'polite',
        'aria-valuemin': total ? 1 : undefined,
        'aria-valuemax': total || undefined,
        'aria-valuenow': total ? this.current : undefined,
        'data-current': this.current,
        'data-total': total,
        'data-first': this.first,
        'data-last': this.last,
        'data-test-jn-part': 'progress',
      },
    }
  }

  /** Whether a navigation button shows now. */
  isVisible(kind: 'previous' | 'skip' | 'next' | 'submit'): boolean {
    switch (kind) {
      case 'previous':
        return this.total > 1 && !this.first
      case 'skip':
        return this.activeRequired === false
      case 'next':
        return this.total > 1 && !this.last
      case 'submit':
        return this.total > 0 && this.last
    }
  }

  /** What a navigation button renders: shown or hidden (and inert), and its click. */
  navigationSpec(
    kind: 'previous' | 'skip' | 'next' | 'submit',
    { disabled = false }: QuestionnaireNavigationOptions,
  ): PartSpec<HTMLButtonElement> {
    const visible = this.isVisible(kind)
    const confirms = kind === 'next' || kind === 'submit'
    const shortcut = visible && !disabled && confirms ? 'Enter' : null
    const click =
      kind === 'previous' ? this.goPrevious : kind === 'skip' ? this.skipCurrent : this.goNext
    return {
      attributes: {
        type: kind === 'submit' ? 'submit' : 'button',
        disabled,
        hidden: !visible,
        inert: !visible,
        'aria-hidden': visible ? undefined : 'true',
        'aria-keyshortcuts': shortcut,
        tabindex: visible ? undefined : '-1',
        'data-disabled': disabled,
        'data-shortcut': shortcut,
        'data-status': this.activeStatus,
        'data-visible': visible,
        'data-hidden': !visible,
        'data-test-jn-part': kind,
      },
      on: kind === 'submit' ? {} : { click: () => click() },
    }
  }
}

/** Where a `QuestionnaireItemState` reads its settings. */
export interface QuestionnaireItemOptions {
  /** Its name: the form field's, and the item's in `@items`, `@item` and `@defaultItem`. */
  name: () => string
  /** Whether it must be answered: it can't be skipped. */
  required?: () => boolean | undefined
  /** Whether it takes more than one fixed answer (checkboxes, not radios). */
  multiple?: () => boolean | undefined
  /** Whether it is left out: skipped by navigation, not submitted. */
  disabled?: () => boolean | undefined
  /** Whether the caller's own validation found it invalid. */
  invalid?: () => boolean | undefined
  /** Called with its status whenever that changes. */
  onStatusChange?: () => ((status: QuestionnaireItemStatus) => void) | undefined
}

/**
 * One item of a questionnaire: a `<fieldset>` of answers (fixed choices and a freeform input),
 * its status, and its validation, as `@shadcn/react`'s `Questionnaire.Item`.
 */
export class QuestionnaireItemState {
  readonly questionnaire: QuestionnaireState
  readonly #owner: object
  readonly #options: QuestionnaireItemOptions
  readonly #answers = new Set<QuestionnaireAnswerState>()
  readonly #descriptions = new Set<Element>()
  readonly #errors = new Set<Element>()
  /** Bumped after answers, descriptions or errors come or go. */
  @tracked revision = 0
  #bumping = false
  /** The selected answers' ids once someone has chosen; `null` while they are the defaults. */
  @tracked selection: string[] | null = null
  @tracked skipped = false
  @tracked validationAttempted = false
  #reported: QuestionnaireItemStatus = 'unanswered'
  /** The fieldset, once rendered. */
  element: HTMLFieldSetElement | null = null

  /** Put it on the `<fieldset>`. */
  readonly item: PartModifier<HTMLFieldSetElement>
  /** Put it on the title (a `<legend>`, or your own heading). */
  readonly title: PartModifier
  /** Put it on a description: the item's `aria-describedby` names it. */
  readonly description: PartModifier
  /** Put it on the element that holds the choices. */
  readonly choices: PartModifier
  /** Put it on the error message, shown while the item is invalid. */
  readonly error: PartModifier

  constructor(owner: object, questionnaire: QuestionnaireState, options: QuestionnaireItemOptions) {
    this.#owner = owner
    this.questionnaire = questionnaire
    this.#options = options
    this.item = part<HTMLFieldSetElement>(() => this.itemSpec())
    this.title = part(() => this.titleSpec())
    this.description = part(() => this.descriptionSpec())
    this.choices = part(() => ({
      attributes: {
        'data-shortcuts': this.questionnaire.shortcuts,
        'data-test-jn-part': 'choices',
      },
    }))
    this.error = part(() => this.errorSpec())
  }

  /**
   * Registers an element for `aria-describedby`. Its id is read once the render is over, so an
   * id another part gives it (a dialog's description has the dialog's) is the one named; one
   * with none then gets an id of its own.
   */
  #describe(element: Element, elements: Set<Element>): () => void {
    elements.add(element)
    this.bump()
    return () => {
      elements.delete(element)
      this.bump()
    }
  }

  /** The ids of the registered elements, giving one with none an id of its own. */
  #ids(elements: Set<Element>): string[] {
    return [...elements].map(element => {
      if (!element.id) element.id = idFor(element, 'questionnaire')
      return element.id
    })
  }

  get name(): string {
    return this.#options.name()
  }

  get required(): boolean {
    return Boolean(this.#options.required?.())
  }

  get multiple(): boolean {
    return Boolean(this.#options.multiple?.())
  }

  get disabled(): boolean {
    return Boolean(this.#options.disabled?.())
  }

  /** Whether it is the item the questionnaire shows. */
  get isActive(): boolean {
    return !this.disabled && this.questionnaire.activeName === this.name
  }

  /** @internal Re-renders what depends on the answers, after the render that changed them. */
  bump(): void {
    if (this.#bumping) return
    this.#bumping = true
    afterRender(this.#owner, () => {
      this.#bumping = false
      this.revision += 1
      this.questionnaire.bump()
      this.reportStatus()
    })
  }

  /** @internal An answer comes; the returned function is for when it goes. */
  register(answer: QuestionnaireAnswerState): () => void {
    this.#answers.add(answer)
    this.bump()
    return () => {
      this.#answers.delete(answer)
      this.bump()
    }
  }

  /** Every answer control, in document order. */
  get controls(): QuestionnaireAnswerState[] {
    void this.revision
    return [...this.#answers].sort(byDocumentOrder)
  }

  /** The answers that aren't disabled, in document order. */
  get answers(): QuestionnaireAnswerState[] {
    return this.controls.filter(answer => !answer.isDisabled)
  }

  /** Whether it has a freeform answer, which makes its fixed answers' `required` unneeded. */
  get hasInputAnswer(): boolean {
    return this.answers.some(answer => answer instanceof QuestionnaireInputState)
  }

  /** The answers selected by default: the first, for a single answer. */
  get #defaults(): string[] {
    const ids = this.controls.filter(answer => answer.defaultSelected).map(answer => answer.id)
    return this.multiple ? ids : ids.slice(0, 1)
  }

  /** Whether an answer is selected: chosen, or for a controlled choice, its `@checked`. */
  isSelected(answer: QuestionnaireAnswerState): boolean {
    if (answer instanceof QuestionnaireChoiceState && answer.isControlled) {
      return !this.skipped && answer.controlledChecked
    }
    return (this.selection ?? this.#defaults).includes(answer.id)
  }

  /**
   * @internal Puts a controlled answer's selection in step with its value, as upstream's
   * `syncControlledAnswerSelection`: selected, it is no longer skipped; deselected, it leaves
   * the rest as they are.
   */
  syncSelection(answer: QuestionnaireAnswerState, selected: boolean): void {
    if (selected) {
      this.select(answer, true)
      return
    }
    const current = this.selection ?? this.#defaults
    if (!current.includes(answer.id)) return
    this.selection = current.filter(id => id !== answer.id)
    this.reportStatus()
  }

  /** Selects or deselects an answer, as someone choosing it does. It is no longer skipped. */
  select(answer: QuestionnaireAnswerState, selected: boolean): void {
    this.skipped = false
    const current = this.selection ?? this.#defaults
    if (!selected) this.selection = current.filter(id => id !== answer.id)
    else if (!this.multiple) this.selection = [answer.id]
    else this.selection = current.includes(answer.id) ? current : [...current, answer.id]
    this.reportStatus()
  }

  /** Whether an answer is selected. */
  get answered(): boolean {
    return this.answers.some(answer => this.isSelected(answer))
  }

  /** `skipped`, `answered` or `unanswered`. */
  get status(): QuestionnaireItemStatus {
    return this.skipped ? 'skipped' : this.answered ? 'answered' : 'unanswered'
  }

  /** Whether the caller's validation found it invalid (`@invalid`). */
  get externallyInvalid(): boolean {
    return Boolean(this.#options.invalid?.())
  }

  /** Whether it may be left: disabled, skipped on purpose, or answered (and not found invalid). */
  get valid(): boolean {
    const intentionallySkipped = this.status === 'skipped' && !this.required
    return (
      this.disabled ||
      intentionallySkipped ||
      (!this.externallyInvalid && this.status === 'answered')
    )
  }

  /** Whether it shows as invalid: found invalid, or not valid once someone tried to leave it. */
  get invalid(): boolean {
    const intentionallySkipped = this.status === 'skipped' && !this.required
    if (this.disabled || intentionallySkipped) return false
    return this.externallyInvalid || (this.validationAttempted && !this.valid)
  }

  /** Calls `@onStatusChange`, once a render is over, when the status has changed. */
  reportStatus(): void {
    afterRender(this.#owner, () => {
      const status = this.status
      if (status === this.#reported) return
      this.#reported = status
      this.#options.onStatusChange?.()?.(status)
    })
  }

  /** Checks it may be left, showing its error when not. */
  validate(): boolean {
    this.validationAttempted = true
    if (!this.valid) return false
    if (!this.questionnaire.nativeValidation) return true
    const invalid = this.answers.find(
      answer =>
        answer.isAnswerFilled && answer.element?.willValidate && !answer.element.validity.valid,
    )
    if (!invalid) return true
    invalid.element!.focus()
    invalid.element!.reportValidity()
    return false
  }

  /** Focuses the item itself (its fieldset), as moving to it does. */
  focus(): void {
    this.element?.focus()
  }

  /** Focuses its chosen freeform answer, else its first control, else itself. */
  focusInvalid(): void {
    const element = this.element
    const filled = element?.querySelector<HTMLInputElement>(
      'input[data-filled][name]:not(:disabled)',
    )
    const first = element?.querySelector<HTMLElement>(
      'input:not([type=hidden]):not(:disabled), textarea:not(:disabled)',
    )
    ;(filled ?? first ?? element)?.focus()
  }

  /** Puts its answers back to their defaults, as a form reset does. */
  reset(): void {
    this.validationAttempted = false
    this.skipped = false
    this.selection = null
    for (const answer of this.#answers) answer.reset()
    this.reportStatus()
  }

  /** Skips it on purpose, clearing its answers, unless it is required. */
  skip(): void {
    if (this.required) return
    this.selection = []
    this.skipped = true
    this.reportStatus()
  }

  /** The shortcut of each fixed answer by value, from `@items`, or `null` without it. */
  get shortcutsByValue(): Map<string, string> | null {
    const questionnaire = this.questionnaire
    if (!questionnaire.definitions) return null
    return shortcutsByChoiceValue(questionnaire.definition(this.name), questionnaire.shortcuts)
  }

  /** A fixed answer's shortcut, or `null`. */
  shortcutFor(answer: QuestionnaireChoiceState): string | null {
    const byValue = this.shortcutsByValue
    if (byValue) return byValue.get(answer.value) ?? null
    const keys = shortcutKeys(this.questionnaire.shortcuts)
    const choices = this.answers.filter(other => other instanceof QuestionnaireChoiceState)
    const index = choices.indexOf(answer)
    return index < 0 ? null : (keys[index] ?? null)
  }

  /** The enabled answer whose control is `element`. */
  answerByElement(element: Element): QuestionnaireAnswerState | null {
    return this.answers.find(answer => answer.element === element) ?? null
  }

  /** The enabled fixed answer a shortcut picks. */
  answerByShortcut(shortcut: string): QuestionnaireChoiceState | null {
    return (
      (this.answers.find(
        answer => answer instanceof QuestionnaireChoiceState && answer.shortcut === shortcut,
      ) as QuestionnaireChoiceState | undefined) ?? null
    )
  }

  /**
   * Moves focus from `element` to the next or previous answer, wrapping, as the up and down
   * arrows do. A radio picks itself as it is focused. Between two radios the browser moves, so
   * this leaves them be; in a freeform answer with text, the arrows stay the caret's.
   */
  moveAnswerFocus(element: Element, direction: 'next' | 'previous'): boolean {
    const answers = this.answers
    const index = answers.findIndex(answer => answer.element === element)
    const current = index < 0 ? null : answers[index]!
    const emptyInput =
      current instanceof QuestionnaireInputState &&
      ['email', 'password', 'search', 'tel', 'text', 'url'].includes(current.element?.type ?? '') &&
      !hasInputValue(current.element?.value)
    if (
      !answers.length ||
      (isTextEntryTarget(element) && !emptyInput) ||
      (index < 0 && element !== this.element)
    ) {
      return false
    }
    const next =
      index < 0
        ? (answers.find(answer => answer.isAnswerFilled) ??
          (direction === 'next' ? answers[0] : answers[answers.length - 1]))
        : answers[(index + (direction === 'next' ? 1 : -1) + answers.length) % answers.length]
    if (!next?.element || next.element === element) return false
    if (index >= 0 && isRadioTarget(element) && isRadioTarget(next.element)) return false
    next.element.focus()
    if (next instanceof QuestionnaireChoiceState && isRadioTarget(next.element))
      next.element.click()
    return true
  }

  /** The ids its `aria-describedby` names: its descriptions, and its errors while invalid. */
  get describedBy(): string | undefined {
    void this.revision
    const ids = [...this.#ids(this.#descriptions), ...(this.invalid ? this.#ids(this.#errors) : [])]
    return ids.join(' ') || undefined
  }

  /** The keys it answers to while active, for `aria-keyshortcuts`. */
  get keyShortcuts(): string | undefined {
    if (!this.isActive) return undefined
    const questionnaire = this.questionnaire
    const { back, forward } = questionnaire.arrowKeys(this.element)
    return (
      [
        'Meta+Enter Control+Enter',
        this.answers.length ? 'ArrowUp ArrowDown' : undefined,
        questionnaire.first ? undefined : back,
        !questionnaire.last && this.status !== 'unanswered' ? forward : undefined,
      ]
        .filter(Boolean)
        .join(' ') || undefined
    )
  }

  /** What the fieldset renders: hidden and inert unless active, and its state. */
  itemSpec(): PartSpec<HTMLFieldSetElement> {
    const active = this.isActive
    const invalid = this.invalid
    return {
      attributes: {
        'aria-describedby': this.describedBy,
        'aria-invalid': invalid ? 'true' : undefined,
        'aria-keyshortcuts': this.keyShortcuts,
        disabled: this.disabled,
        hidden: !active,
        inert: !active,
        tabindex: '-1',
        'data-active': active,
        'data-disabled': this.disabled,
        'data-invalid': invalid,
        'data-multiple': this.multiple,
        'data-required': this.required,
        'data-status': this.status,
        'data-test-jn-part': 'item',
        'data-test-jn-value': this.name,
      },
      element: element => {
        this.element = element
        this.questionnaire.bump()
        const unregister = this.questionnaire.register(this)
        return () => {
          unregister()
          if (this.element === element) this.element = null
        }
      },
    }
  }

  /** What the title renders. */
  titleSpec(): PartSpec {
    return { attributes: { 'data-test-jn-part': 'title' } }
  }

  /** What a description renders: an id (its own, or one it is given) the item names. */
  descriptionSpec(): PartSpec {
    return {
      attributes: { 'data-test-jn-part': 'description' },
      element: element => this.#describe(element, this.#descriptions),
    }
  }

  /** The default error message: the required or the optional one. */
  get defaultError(): string {
    return this.required
      ? 'Choose an answer to continue.'
      : 'Choose an answer or skip this question.'
  }

  /** What the error renders: shown, as an alert, only while the item is invalid. */
  errorSpec(): PartSpec {
    const invalid = this.invalid
    return {
      attributes: {
        hidden: !invalid,
        role: invalid ? 'alert' : undefined,
        'data-invalid': invalid,
        'data-test-jn-part': 'error',
      },
      element: element => this.#describe(element, this.#errors),
    }
  }
}

/** A fixed answer or a freeform one: what an item's answers have in common. */
export abstract class QuestionnaireAnswerState {
  readonly item: QuestionnaireItemState
  /** The control's id, which a `<label>` around it doesn't need, but `aria-*` may. */
  readonly id: string
  /** The control (`<input>`), once rendered. */
  element: HTMLInputElement | null = null

  constructor(item: QuestionnaireItemState) {
    this.item = item
    this.id = idFor(this, 'answer')
  }

  /** Whether it can't be chosen: its own `@disabled`, or its item's. */
  abstract get isDisabled(): boolean
  /** Whether it is selected by default. */
  abstract get defaultSelected(): boolean
  /** Whether it counts as given, for Enter to confirm it. */
  abstract get isAnswerFilled(): boolean
  /** Puts its control back as it started, as a form reset does. */
  abstract reset(): void

  /** Whether it is selected now. */
  get isSelected(): boolean {
    return this.item.isSelected(this)
  }

  /** @internal Registers the control's element with its item. */
  protected attach(element: HTMLInputElement): () => void {
    this.element = element
    const unregister = this.item.register(this)
    return () => {
      unregister()
      if (this.element === element) this.element = null
    }
  }
}

/** Where a `QuestionnaireChoiceState` reads its settings. */
export interface QuestionnaireChoiceOptions {
  /** The value it submits. */
  value: () => string
  /** Whether it is checked, when the caller controls it. */
  checked?: () => boolean | undefined
  /** Whether it starts checked, when uncontrolled. */
  defaultChecked?: () => boolean | undefined
  /** Whether it can't be chosen. */
  disabled?: () => boolean | undefined
  /**
   * Called as it is checked or unchecked, with the `change` event. Calling `preventDefault()`
   * on the event keeps the questionnaire from taking the change.
   */
  onCheckedChange?: () => ((checked: boolean, event: Event) => void) | undefined
}

/**
 * A fixed answer: a radio (or a checkbox, in an item that takes several) inside a `<label>`,
 * with the rest of the label its text, and its shortcut key, as `Questionnaire.Choice`.
 */
export class QuestionnaireChoiceState extends QuestionnaireAnswerState {
  readonly #options: QuestionnaireChoiceOptions

  /** Put it on the `<label>` around the choice. */
  readonly choice: PartModifier
  /** Put it on the `<input>`. */
  readonly input: PartModifier<HTMLInputElement>
  /** Put it on the element that holds the choice's text. */
  readonly label: PartModifier
  /** Put it on the element that shows its shortcut key. */
  readonly shortcutKey: PartModifier
  /**
   * Put it on the `<input>` after `input`: it keeps the control's `checked` (and the
   * `defaultChecked` a form reset returns to) in step with the questionnaire.
   */
  readonly sync: typeof Modifier<{ Element: HTMLInputElement }>

  constructor(item: QuestionnaireItemState, options: QuestionnaireChoiceOptions) {
    super(item)
    this.#options = options
    this.choice = part(() => ({
      attributes: {
        ...this.stateAttributes,
        'data-test-jn-part': 'choice',
        'data-test-jn-value': this.value,
      },
    }))
    this.input = part<HTMLInputElement>(() => this.inputSpec())
    this.label = part(() => ({ attributes: { 'data-test-jn-part': 'choice-label' } }))
    this.shortcutKey = part(() => ({
      attributes: {
        'aria-hidden': 'true',
        hidden: this.shortcut === null,
        'data-shortcut': this.shortcut,
        'data-test-jn-part': 'shortcut',
      },
    }))
    // eslint-disable-next-line @typescript-eslint/no-this-alias -- the modifier's class reads it
    const choice = this
    this.sync = class SyncChecked extends Modifier<{ Element: HTMLInputElement }> {
      override modify(element: HTMLInputElement): void {
        element.defaultChecked = choice.defaultCheckedProperty
        if (element.checked !== choice.isChecked) element.checked = choice.isChecked
      }
    }
  }

  get value(): string {
    return this.#options.value()
  }

  /** Whether the caller controls it (`@checked`). */
  get isControlled(): boolean {
    return this.#options.checked?.() !== undefined
  }

  /** The caller's `@checked`. */
  get controlledChecked(): boolean {
    return Boolean(this.#options.checked?.())
  }

  /** Its own `@disabled`. */
  get ownDisabled(): boolean {
    return Boolean(this.#options.disabled?.())
  }

  get isDisabled(): boolean {
    return this.item.disabled || this.ownDisabled
  }

  get defaultSelected(): boolean {
    return !this.isControlled && Boolean(this.#options.defaultChecked?.())
  }

  /** What a form reset puts back: the default, or for a controlled choice, its `@checked`. */
  get defaultCheckedProperty(): boolean {
    return this.isControlled ? this.controlledChecked : Boolean(this.#options.defaultChecked?.())
  }

  /** Whether it is checked. */
  get isChecked(): boolean {
    return this.isSelected
  }

  get isAnswerFilled(): boolean {
    return this.element?.checked ?? false
  }

  /** `checkbox` in an item that takes several answers, else `radio`. */
  get type(): 'checkbox' | 'radio' {
    return this.item.multiple ? 'checkbox' : 'radio'
  }

  /** Its shortcut key, or `null`. */
  get shortcut(): string | null {
    return this.item.shortcutFor(this)
  }

  reset(): void {
    // The form's own reset puts the control back from `defaultChecked`; `sync` keeps it there.
  }

  /** The state its label and input render, as upstream's `data-*`. */
  get stateAttributes(): Record<string, string | boolean | null | undefined> {
    const checked = this.isChecked
    return {
      'data-checked': checked,
      'data-unchecked': !checked,
      'data-disabled': this.isDisabled,
      'data-invalid': this.item.invalid,
      'data-shortcut': this.shortcut,
      'data-type': this.type,
    }
  }

  #handleChange = (event: Event): void => {
    const element = event.currentTarget as HTMLInputElement
    this.#options.onCheckedChange?.()?.(element.checked, event)
    if (!event.defaultPrevented) {
      if (!this.isControlled) this.item.select(this, element.checked)
      else if (this.item.skipped && this.controlledChecked === element.checked) {
        this.item.select(this, this.controlledChecked)
      }
    }
    // A controlled choice shows its `@checked` again, whatever the click did.
    afterRender(this, () => {
      if (element.checked !== this.isChecked) element.checked = this.isChecked
    })
  }

  /** What the `<input>` renders. */
  inputSpec(): PartSpec<HTMLInputElement> {
    const item = this.item
    const disabled = this.isDisabled
    return {
      attributes: {
        ...this.stateAttributes,
        id: this.id,
        type: this.type,
        name: item.status === 'skipped' ? undefined : item.name,
        value: this.value,
        disabled,
        required: item.required && !item.multiple && !item.hasInputAnswer,
        'aria-invalid': item.invalid ? 'true' : undefined,
        'aria-keyshortcuts': answerKeyShortcuts(this.shortcut, !disabled && this.isChecked),
        'data-test-jn-part': 'choice-input',
      },
      on: { change: this.#handleChange },
      element: element => this.attach(element),
    }
  }
}

/** Where a `QuestionnaireInputState` reads its settings. */
export interface QuestionnaireInputOptions {
  /** The value, when the caller controls it. */
  value?: () => string | undefined
  /** The value it starts with, when uncontrolled. */
  defaultValue?: () => string | undefined
  /** Whether it can't be typed in. */
  disabled?: () => boolean | undefined
  /** Called with the new value as someone types. */
  onValueChange?: () => ((value: string) => void) | undefined
}

/**
 * A freeform answer: a text `<input>` beside the fixed answers, as `Questionnaire.Input`. It
 * is the item's answer while it has text and was the last answer given; only then does it
 * belong to the form (so it submits), and choosing a fixed answer of a single-answer item
 * takes over from it.
 */
export class QuestionnaireInputState extends QuestionnaireAnswerState {
  readonly #options: QuestionnaireInputOptions
  /** Whether it has text, once someone has typed; `null` while it shows its default. */
  @tracked typedFilled: boolean | null = null
  /** The controlled value its selection was last put in step with (`NOT_SYNCED` before that). */
  #synced: string | undefined | typeof NOT_SYNCED = NOT_SYNCED

  /** Put it on the `<input>`, with `{{nativeValue}}` for its value. */
  readonly input: PartModifier<HTMLInputElement>

  constructor(item: QuestionnaireItemState, options: QuestionnaireInputOptions) {
    super(item)
    this.#options = options
    this.input = part<HTMLInputElement>(() => this.inputSpec())
  }

  get isControlled(): boolean {
    return this.#options.value?.() !== undefined
  }

  get isDisabled(): boolean {
    return this.item.disabled || Boolean(this.#options.disabled?.())
  }

  get defaultSelected(): boolean {
    return !this.isControlled && hasInputValue(this.#options.defaultValue?.())
  }

  /** Whether it has text. */
  get filled(): boolean {
    if (this.isControlled) return hasInputValue(this.#options.value?.())
    return this.typedFilled ?? hasInputValue(this.#options.defaultValue?.())
  }

  get isAnswerFilled(): boolean {
    return Boolean(this.element?.hasAttribute('name')) && hasInputValue(this.element?.value)
  }

  /**
   * Hears the text change: selects it while it has text, as typing an answer does. A controlled
   * one only tells `@onValueChange`: its selection follows the value it is given back.
   */
  onValueChange = (value: string): void => {
    this.#options.onValueChange?.()?.(value)
    if (this.isControlled) return
    const filled = hasInputValue(value)
    this.typedFilled = filled
    this.item.select(this, filled)
  }

  /**
   * A controlled input is the answer while its value has text: from the first render, and
   * again each time the value changes (typed and passed back, or set by its host), as
   * upstream's layout effect has it. A choice picked since leaves it unselected until then.
   */
  #syncControlled(): void {
    const value = this.#options.value?.()
    if (value === this.#synced) return
    this.#synced = value
    afterRender(this, () => {
      if (this.isControlled) this.item.syncSelection(this, this.filled)
    })
  }

  reset(): void {
    this.typedFilled = null
    if (this.isControlled) {
      // The item's reset clears its selection; put the controlled value's back, as upstream's
      // effect does on a reset.
      this.#synced = NOT_SYNCED
      afterRender(this, () => {
        if (this.isControlled) this.item.syncSelection(this, this.filled)
      })
    }
    // An input that wasn't the answer is outside the form, which can't reset it.
    const element = this.element
    if (element && !this.isControlled) {
      const value = this.#options.defaultValue?.() ?? ''
      afterRender(this, () => {
        if (element.value !== value) element.value = value
      })
    }
  }

  /** What the `<input>` renders. */
  inputSpec(): PartSpec<HTMLInputElement> {
    if (this.isControlled) this.#syncControlled()
    const item = this.item
    const disabled = this.isDisabled
    const selected = this.isSelected
    const filled = this.filled
    return {
      attributes: {
        id: this.id,
        name: selected ? item.name : undefined,
        // Outside the form until it is the answer, so a draft doesn't submit.
        form: selected ? undefined : '',
        disabled,
        'aria-invalid': item.invalid ? 'true' : undefined,
        'aria-keyshortcuts': answerKeyShortcuts(null, !disabled && filled && selected),
        'data-filled': filled,
        'data-empty': !filled,
        'data-disabled': disabled,
        'data-invalid': item.invalid,
        'data-test-jn-part': 'input',
      },
      element: element => this.attach(element),
    }
  }
}
