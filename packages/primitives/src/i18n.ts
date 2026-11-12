import { capabilities, setHelperManager } from '@ember/helper'
import type Owner from '@ember/owner'
import { findOwner } from './store.ts'

/**
 * A built-in string: a calendar's "Previous month", a dialog's "Close". Every package exports
 * its own from `<package>/messages`, as data for a translation catalog.
 */
export interface Message {
  /** Stable key, `joinery.<component>.<name>`: `joinery.calendar.previousMonth`. */
  id: string
  /** English text, and the gettext msgid. Placeholders are `{name}`. */
  message: string
  /** English plural, and the gettext msgid_plural. Chosen by `values.count`. */
  plural?: string
  /** gettext msgctxt, to tell apart equal English strings with different meanings. */
  context?: string
  /** A note for translators (gettext `#.` comment, ICU description). */
  description?: string
}

/**
 * What translates Joinery's built-in strings, registered as `translator:main`:
 *
 *   owner.register('translator:main', translator, { instantiate: false })
 */
export interface Translator {
  /** BCP 47 locale. Make it tracked, so a locale change re-renders. */
  readonly locale: string
  /** The translated, interpolated string. Falls back to English itself when it has none. */
  t(message: Message, values?: Record<string, unknown>): string
}

const PLACEHOLDER = /\{(\w+)\}/g

/**
 * A message in English: `plural` when `values.count` is a number English doesn't call one,
 * with each `{name}` replaced by `String(values[name])` (an unknown one is left as written).
 */
export function format(message: Message, values?: Record<string, unknown>): string {
  const count = values?.['count']
  const text =
    message.plural !== undefined &&
    typeof count === 'number' &&
    new Intl.PluralRules('en').select(count) !== 'one'
      ? message.plural
      : message.message
  if (!values) return text
  return text.replace(PLACEHOLDER, (placeholder, name: string) =>
    Object.hasOwn(values, name) ? String(values[name]) : placeholder,
  )
}

/** The app's `translator:main`, if it registered one. */
export function translator(context: unknown): Translator | undefined {
  return findOwner(context)?.lookup('translator:main') as Translator | undefined
}

/**
 * A built-in string in the app's language: its translator's, or English without one. Pass the
 * component (or anything with an owner) as the context.
 *
 *   translate(this, messages.breadcrumbLabel)
 */
export function translate(
  context: unknown,
  message: Message,
  values?: Record<string, unknown>,
): string {
  return translator(context)?.t(message, values) ?? format(message, values)
}

interface TranslateHelperArgs {
  positional: [Message, Record<string, unknown>?]
}

/** Lets templates call `(t message values)`: the helper manager knows the owner. */
class TranslateHelperManager {
  capabilities = capabilities('3.23', { hasValue: true })

  readonly owner: Owner

  constructor(owner: Owner) {
    this.owner = owner
  }

  createHelper(_definition: unknown, args: TranslateHelperArgs): TranslateHelperArgs {
    return args
  }

  getValue({ positional: [message, values] }: TranslateHelperArgs): string {
    return translate(this.owner, message, values)
  }
}

/**
 * `translate` for a template, where a template-only component has no `this` to pass:
 * `{{t messages.dialogClose}}`, or `{{t messages.carouselSlide (hash index=1 count=3)}}`.
 */
export const t = (() => '') as unknown as (
  message: Message,
  values?: Record<string, unknown>,
) => string

// The owner parameter is typed for 7.x; 6.12's types leave it untyped, so it is annotated here.
setHelperManager((owner: unknown) => new TranslateHelperManager(owner as Owner), t)
