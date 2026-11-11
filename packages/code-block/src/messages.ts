import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/code-block` shows or announces itself, in English, for a
 * translation catalog. An argument (`@copyLabel`, `@copiedLabel`) still beats each one.
 */
export const messages = {
  copy: { id: 'joinery.code-block.copy', message: 'Copy' },
  copied: { id: 'joinery.code-block.copied', message: 'Copied' },
} satisfies Record<string, Message>
