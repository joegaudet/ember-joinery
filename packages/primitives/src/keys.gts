import type { TOC } from '@ember/component/template-only'

/** Keys as a list, or as one string joined with `+`: `['ctrl', 'k']` or `'ctrl+k'`. */
export type Keys = string | readonly string[]

interface NavigatorWithUAData extends Navigator {
  userAgentData?: { platform?: string }
}

/**
 * Whether the page runs on a Mac (or an iPad or iPhone, whose keyboards are the Mac's), where
 * shortcuts use ⌘ and ⌥ in place of Ctrl and Alt. It is read on each call.
 */
export function isMac(): boolean {
  const nav = navigator as NavigatorWithUAData
  const platform = nav.userAgentData?.platform ?? ''
  return /mac|ios/i.test(platform) || /Mac OS|Macintosh|iPhone|iPad/.test(nav.userAgent)
}

function split(keys: Keys): string[] {
  if (typeof keys !== 'string') return [...keys]
  return keys
    .split('+')
    .map(key => key.trim())
    .filter(Boolean)
}

/** The keys to show: `mac` on a Mac, when given, and `keys` everywhere else. */
function keysFor(keys: Keys, mac: Keys | undefined): string[] {
  return split(mac !== undefined && isMac() ? mac : keys)
}

function separatorOf(separator: string | undefined): string {
  return separator ?? '+'
}

export interface KeySignature {
  Args: {
    /** The harness's name for it (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The key's label: `Ctrl`, `⌘`, `Enter`. */
    default: []
  }
  Element: HTMLElement
}

/**
 * One key on the keyboard, as ember-primitives' `<Key>`: a `<kbd>`, which is what screen
 * readers and browsers expect for keyboard input.
 *
 *   Press <Key>Esc</Key> to close.
 */
export const Key: TOC<KeySignature> = <template>
  <kbd data-slot="key" data-test-jn="key" data-test-jn-name={{@name}} ...attributes>{{yield}}</kbd>
</template>

export interface KeyComboSignature {
  Args: {
    /** The keys, in order: `"ctrl+k"` or `(array "ctrl" "k")`. */
    keys: Keys
    /** The keys to show on a Mac instead, such as `"⌘+k"`. */
    mac?: Keys
    /** What goes between the keys. Default `+`. */
    separator?: string
    /** The harness's name for it (`data-test-jn-name`). */
    name?: string
  }
  Element: HTMLSpanElement
}

/**
 * A keyboard shortcut, as ember-primitives' `<KeyCombo>`: each key in its own `<Key>`, with a
 * separator between them, and the Mac's keys on a Mac when `@mac` gives them.
 *
 *   <KeyCombo @keys="ctrl+k" @mac="⌘+k" />
 */
export const KeyCombo: TOC<KeyComboSignature> = <template>
  <span data-slot="key-combo" data-test-jn="key-combo" data-test-jn-name={{@name}} ...attributes>
    {{#each (keysFor @keys @mac) as |key index|}}
      {{#if index}}
        <span data-slot="key-combo-separator" data-test-jn-part="separator">
          {{separatorOf @separator}}
        </span>
      {{/if}}
      <Key data-test-jn-part="key" data-test-jn-value={{key}}>{{key}}</Key>
    {{/each}}
  </span>
</template>
