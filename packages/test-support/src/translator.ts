import { getContext } from '@ember/test-helpers'
import type { TestHooks } from './test-hooks.ts'

/** A built-in string, as `@ember-joinery/primitives/i18n` declares it (the msgid contract). */
export interface TranslatorMessage {
  id: string
  message: string
  plural?: string
  context?: string
  description?: string
}

/** What translates Joinery's built-in strings, as `@ember-joinery/primitives/i18n` declares it. */
export interface TestTranslator {
  readonly locale: string
  t(message: TranslatorMessage, values?: Record<string, unknown>): string
}

/**
 * Registers `translator` as the test's `translator:main` before each test, so Joinery's
 * components show their built-in strings through it. Call it after `setupRenderingTest(hooks)`
 * or `setupApplicationTest(hooks)`.
 *
 *   module('in French', function (hooks) {
 *     setupRenderingTest(hooks)
 *     setupTranslator(hooks, myTranslator)
 *   })
 */
export function setupTranslator(hooks: TestHooks, translator: TestTranslator): void {
  hooks.beforeEach(() => {
    const context = getContext() as
      { owner?: { register(name: string, value: unknown, options: object): void } } | undefined
    if (!context?.owner) {
      throw new Error(
        'Joinery: setupTranslator(hooks) found no test owner; call it after setupRenderingTest(hooks) or setupApplicationTest(hooks)',
      )
    }
    context.owner.register('translator:main', translator, { instantiate: false })
  })
}

const ACCENTS: Record<string, string> = {
  a: 'á',
  c: 'ç',
  e: 'é',
  i: 'í',
  n: 'ñ',
  o: 'ó',
  s: 'ś',
  u: 'ú',
  y: 'ý',
  z: 'ź',
  A: 'Á',
  C: 'Ç',
  E: 'É',
  I: 'Í',
  N: 'Ñ',
  O: 'Ó',
  S: 'Ś',
  U: 'Ú',
  Y: 'Ý',
  Z: 'Ź',
}

// The English, accented outside its `{placeholders}`, so a value passed in shows as given.
function accent(text: string): string {
  return text.replace(/\{\w+\}|[A-Za-z]/g, match => ACCENTS[match] ?? match)
}

// shortcut: a local copy of the msgid contract's English formatting, until msgid is published.
function format(message: TranslatorMessage, values?: Record<string, unknown>): string {
  const count = values?.['count']
  const text =
    message.plural !== undefined &&
    typeof count === 'number' &&
    new Intl.PluralRules('en').select(count) !== 'one'
      ? message.plural
      : message.message
  if (!values) return text
  return text.replace(/\{(\w+)\}/g, (placeholder, name: string) =>
    Object.hasOwn(values, name) ? String(values[name]) : placeholder,
  )
}

/**
 * A pseudo-locale (`en-XA`): every string comes out accented and wrapped, `⟦Ćĺóśé⟧`, so a test
 * can tell a built-in string that went through the translator from one that skipped it. Values
 * (a name, a number, a date) are interpolated as given.
 *
 *   setupTranslator(hooks, pseudoTranslator)
 */
export const pseudoTranslator: TestTranslator = {
  locale: 'en-XA',
  t(message, values) {
    const accented = { ...message, message: accent(message.message) }
    if (message.plural !== undefined) accented.plural = accent(message.plural)
    return `⟦${format(accented, values)}⟧`
  },
}
