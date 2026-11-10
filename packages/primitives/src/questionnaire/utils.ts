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
