import { Harness } from './harness.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** Drives a `<Key>` from `@ember-joinery/primitives/keys`: one `<kbd>`. */
export class KeyHarness extends Harness {
  static override component = 'key'

  /** The key's label, as shown. */
  get label(): string {
    return text(this.element)
  }
}

/** Drives a `<KeyCombo>` from `@ember-joinery/primitives/keys`: keys with separators between. */
export class KeyComboHarness extends Harness {
  static override component = 'key-combo'

  /** The keys shown, in order: `['Ctrl', 'K']` (or the `@mac` keys, on a Mac). */
  get keys(): string[] {
    return this.values('key')
  }

  /** Each key's harness, in order. */
  get keyHarnesses(): KeyHarness[] {
    return this.findAll(KeyHarness)
  }

  /** The text between the keys, such as `+`. */
  get separators(): string[] {
    return this.parts('separator').map(text)
  }

  /** The whole shortcut as read: `Ctrl + K`. */
  get label(): string {
    return text(this.element)
  }
}
