import { Harness } from './harness.ts'
import { KeyHarness } from './keys.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Kbd>` from `@ember-joinery/ember`: one key, a styled `<kbd>`. It reads like the
 * primitives' `KeyHarness`.
 *
 *   assert.strictEqual(new KbdHarness('save').label, 'S')
 */
export class KbdHarness extends KeyHarness {
  static override component = 'kbd'
}

/**
 * Drives a `<KbdGroup>` from `@ember-joinery/ember`: keys shown together, as a shortcut.
 *
 *   const bold = new KbdGroupHarness('bold')
 *   assert.deepEqual(bold.keys, ['Ctrl', 'B'])
 *   assert.strictEqual(bold.label, 'Ctrl + B')
 */
export class KbdGroupHarness extends Harness {
  static override component = 'kbd-group'

  /** Each key's harness, in order. */
  get kbds(): KbdHarness[] {
    return this.findAll(KbdHarness)
  }

  /** The keys it shows, in order: `['Ctrl', 'B']`. */
  get keys(): string[] {
    return this.kbds.map(kbd => kbd.label)
  }

  /** Everything it shows, keys and what's between them: `Ctrl + B`. */
  get label(): string {
    return text(this.element)
  }
}
