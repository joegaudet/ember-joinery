// Ported from shadcn-ui/ui `packages/react/src/questionnaire/utils.ts` and `collection.ts`
// (@shadcn/react's Questionnaire, MIT).

/** An item's answer state: nothing chosen, an answer chosen, or skipped on purpose. */
export type QuestionnaireItemStatus = 'unanswered' | 'answered' | 'skipped'

/** Which keys pick a fixed answer: `letters` (A–Z) or `numbers` (1–9). */
export type QuestionnaireShortcutMode = 'letters' | 'numbers'

/** A fixed answer, as the root's `@items` describes it. */
export interface QuestionnaireChoiceDefinition {
  value: string
  disabled?: boolean
}

/**
 * An item, as the root's `@items` describes it: its name, whether it must be answered or is
 * left out, and its fixed answers in order (for the shortcuts). Pass the collection to the
 * root so progress, the actions and the shortcuts are right from the first render.
 */
export interface QuestionnaireItemDefinition {
  name: string
  required?: boolean
  disabled?: boolean
  choices?: readonly QuestionnaireChoiceDefinition[]
}

/** Whether a value has any text, as upstream's `hasInputValue`. */
export function hasInputValue(value: unknown): boolean {
  if (Array.isArray(value)) return value.some(item => String(item).trim().length > 0)
  return value !== undefined && value !== null && String(value).trim().length > 0
}

/** The keys a shortcut mode gives out, in order. */
export function shortcutKeys(shortcuts: QuestionnaireShortcutMode | null | undefined): string[] {
  if (shortcuts === 'letters') {
    return Array.from({ length: 26 }, (_, index) => String.fromCharCode(65 + index))
  }
  if (shortcuts === 'numbers') return Array.from({ length: 9 }, (_, index) => String(index + 1))
  return []
}

/** The shortcut a key press names, or `null`: a letter in any case, or a digit. */
export function shortcutFromKey(key: string, shortcuts: QuestionnaireShortcutMode): string | null {
  const normalized = shortcuts === 'letters' ? key.toUpperCase() : key
  return shortcutKeys(shortcuts).includes(normalized) ? normalized : null
}

/** An answer's `aria-keyshortcuts`: its shortcut, and `Enter` once it is filled. */
export function answerKeyShortcuts(shortcut: string | null, filled: boolean): string | undefined {
  return [shortcut, filled ? 'Enter' : null].filter(Boolean).join(' ') || undefined
}

/** Whether a key press is typing into a field, which arrows and letters must be left to. */
export function isTextEntryTarget(element: Element): boolean {
  if (element instanceof HTMLTextAreaElement || element instanceof HTMLSelectElement) return true
  if (element instanceof HTMLInputElement) {
    return !['button', 'checkbox', 'radio', 'reset', 'submit'].includes(element.type)
  }
  return element instanceof HTMLElement && element.isContentEditable
}

/** Whether an element is a radio, whose arrow keys the browser already handles. */
export function isRadioTarget(element: Element): boolean {
  return element instanceof HTMLInputElement && element.type === 'radio'
}

/** Sorts things with elements into document order; those without one go last. */
export function byDocumentOrder<T extends { element: Element | null }>(a: T, b: T): number {
  if (a.element === b.element) return 0
  if (!a.element) return 1
  if (!b.element) return -1
  const position = a.element.compareDocumentPosition(b.element)
  if (position & Node.DOCUMENT_POSITION_FOLLOWING) return -1
  if (position & Node.DOCUMENT_POSITION_PRECEDING) return 1
  return 0
}

/** The item a questionnaire starts on: `defaultItem` when it names an enabled item, else the first. */
export function initialItemName(
  items: readonly QuestionnaireItemDefinition[] | undefined,
  defaultItem: string | undefined,
): string | null {
  if (!items) return defaultItem ?? null
  const named = defaultItem ? items.find(item => item.name === defaultItem) : undefined
  if (named && !named.disabled) return named.name
  return items.find(item => !item.disabled)?.name ?? null
}

/** Each fixed answer's shortcut, from the item's definition: enabled choices, in order. */
export function shortcutsByChoiceValue(
  item: QuestionnaireItemDefinition | undefined,
  shortcuts: QuestionnaireShortcutMode | null,
): Map<string, string> {
  const map = new Map<string, string>()
  if (!item || !shortcuts) return map
  const keys = shortcutKeys(shortcuts)
  let index = 0
  for (const choice of item.choices ?? []) {
    if (choice.disabled) continue
    const key = keys[index]
    if (!key) break
    map.set(choice.value, key)
    index += 1
  }
  return map
}

/**
 * A rendered item, as the development warnings compare it with `@items`: its name, its own
 * `@disabled` and `@required`, and its fixed answers in document order, each with its own
 * `@disabled` (upstream's `ItemRegistration`).
 */
export interface QuestionnaireItemRegistration {
  name: string
  disabled: boolean
  required: boolean
  choices: readonly { value: string; disabled: boolean }[]
}

/**
 * What is wrong with `@items` and `@defaultItem` on their own: upstream's
 * `getCollectionDefinitionWarnings`, its messages in Joinery's terms.
 */
export function collectionDefinitionWarnings(
  items: readonly QuestionnaireItemDefinition[],
  defaultItem: string | undefined,
): string[] {
  const warnings: string[] = []
  const names = new Set<string>()
  for (const item of items) {
    if (names.has(item.name)) warnings.push(`Item name "${item.name}" is defined more than once.`)
    names.add(item.name)
    const values = new Set<string>()
    for (const choice of item.choices ?? []) {
      if (values.has(choice.value)) {
        warnings.push(
          `Choice value "${choice.value}" is defined more than once in item "${item.name}".`,
        )
      }
      values.add(choice.value)
    }
  }
  if (defaultItem) {
    const named = items.find(item => item.name === defaultItem)
    if (!named || named.disabled) {
      warnings.push(
        `@defaultItem "${defaultItem}" does not identify an enabled item. The first enabled item will be used instead.`,
      )
    }
  }
  return warnings
}

/**
 * Where the rendered items and choices part from `@items`: upstream's
 * `getCollectionRegistrationWarnings`, its messages in Joinery's terms.
 */
export function collectionRegistrationWarnings(
  items: readonly QuestionnaireItemDefinition[],
  registrations: readonly QuestionnaireItemRegistration[],
  shortcuts: QuestionnaireShortcutMode | null,
): string[] {
  const warnings: string[] = []
  const rendered = new Map(registrations.map(registration => [registration.name, registration]))
  for (const definition of items) {
    const registration = rendered.get(definition.name)
    if (!registration) {
      if (!definition.disabled) {
        warnings.push(`Item "${definition.name}" is defined in @items but has no rendered Item.`)
      }
      continue
    }
    if (registration.disabled !== Boolean(definition.disabled)) {
      warnings.push(
        `Item "${definition.name}" has different disabled values in @items and its Item.`,
      )
    }
    if (registration.required !== Boolean(definition.required)) {
      warnings.push(
        `Item "${definition.name}" has different required values in @items and its Item.`,
      )
    }
    const defined = definition.choices ?? []
    const definedByValue = new Map(defined.map(choice => [choice.value, choice]))
    const renderedByValue = new Map(registration.choices.map(choice => [choice.value, choice]))
    for (const choice of defined) {
      const renderedChoice = renderedByValue.get(choice.value)
      if (!renderedChoice) {
        warnings.push(
          `Choice "${choice.value}" is defined for item "${definition.name}" but has no rendered Choice.`,
        )
        continue
      }
      if (renderedChoice.disabled !== Boolean(choice.disabled)) {
        warnings.push(
          `Choice "${choice.value}" in item "${definition.name}" has different disabled values in @items and its Choice.`,
        )
      }
    }
    if (!shortcuts) continue
    for (const choice of registration.choices) {
      if (!definedByValue.has(choice.value)) {
        warnings.push(
          `Rendered choice "${choice.value}" in item "${definition.name}" is missing from @items and will not receive a shortcut.`,
        )
      }
    }
    const definedOrder = defined.filter(choice => !choice.disabled).map(choice => choice.value)
    const renderedOrder = registration.choices
      .filter(choice => !choice.disabled)
      .map(choice => choice.value)
    const sameChoices =
      definedOrder.length > 0 &&
      definedOrder.length === renderedOrder.length &&
      definedOrder.every(value => renderedOrder.includes(value))
    if (sameChoices && definedOrder.some((value, index) => value !== renderedOrder[index])) {
      warnings.push(
        `Choice order for item "${definition.name}" differs between @items and the rendered Choices.`,
      )
    }
  }
  const defined = new Set(items.map(item => item.name))
  for (const registration of registrations) {
    if (!registration.disabled && !defined.has(registration.name)) {
      warnings.push(
        `Rendered item "${registration.name}" is missing from @items and is excluded from the questionnaire.`,
      )
    }
  }
  return warnings
}
