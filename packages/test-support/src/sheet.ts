import { DialogHarness } from './dialog.ts'

/**
 * Drives a `<Sheet>`: a dialog that slides in from an edge of the screen.
 *
 *   const sheet = new SheetHarness()
 *   await sheet.open()
 *   assert.strictEqual(sheet.side, 'right')
 */
export class SheetHarness extends DialogHarness {
  static override component = 'sheet'

  /** The edge it comes in from: `top`, `right`, `bottom` or `left` (`data-side`). */
  get side(): string | null {
    return this.content?.getAttribute('data-side') ?? null
  }
}
