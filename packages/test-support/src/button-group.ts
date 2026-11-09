import { ButtonHarness } from './button.ts'
import { Harness } from './harness.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<ButtonGroup>` from `@ember-joinery/ember`: its name, its orientation, and the
 * buttons, nested groups, separators and text inside it.
 *
 *   const toolbar = new ButtonGroupHarness('actions') // <ButtonGroup @name="actions">
 *   assert.strictEqual(toolbar.label, 'Media controls')
 *   await toolbar.find(ButtonHarness, 'archive').click()
 */
export class ButtonGroupHarness extends Harness {
  static override component = 'button-group'

  /** Its role, `group`. */
  get role(): string | null {
    return this.element.getAttribute('role')
  }

  /**
   * Its accessible name: `aria-label`, else the text of the elements `aria-labelledby` names,
   * else `''` (a group has no name of its own).
   */
  get label(): string {
    const element = this.element
    const label = element.getAttribute('aria-label')
    if (label) return label.trim()
    const labelledBy = element.getAttribute('aria-labelledby')
    if (!labelledBy) return ''
    return labelledBy
      .split(/\s+/)
      .map(id => element.ownerDocument.getElementById(id))
      .filter((found): found is HTMLElement => Boolean(found))
      .map(text)
      .join(' ')
  }

  /** Its `@orientation`: `horizontal` or `vertical`. */
  get orientation(): string {
    return this.element.getAttribute('data-orientation') ?? 'horizontal'
  }

  /** A harness for each button in it, nested groups' included, in order. */
  get buttons(): ButtonHarness[] {
    return this.findAll(ButtonHarness)
  }

  /** A harness for each group nested in it, in order. */
  get groups(): ButtonGroupHarness[] {
    return this.findAll(ButtonGroupHarness)
  }

  /** Its own separators (not a nested group's), in order. */
  get separators(): HTMLElement[] {
    return this.parts('separator')
  }

  /** The text of each of its own text parts, in order. */
  get texts(): string[] {
    return this.parts('text').map(text)
  }
}
