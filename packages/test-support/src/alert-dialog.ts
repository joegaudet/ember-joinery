import { click } from '@ember/test-helpers'
import { DialogHarness } from './dialog.ts'

/**
 * Drives an `<AlertDialog>`: a dialog with an action and a cancel button, which a press outside
 * doesn't close.
 *
 *   const alert = new AlertDialogHarness('delete')
 *   await alert.open()
 *   assert.dom(alert.cancelButton).isFocused()
 *   await alert.confirm()
 */
export class AlertDialogHarness extends DialogHarness {
  static override component = 'alert-dialog'

  /** The action, which confirms. */
  get actionButton(): HTMLElement {
    return this.part('action')
  }

  /** The cancel button, which has focus when it opens. */
  get cancelButton(): HTMLElement {
    return this.part('cancel')
  }

  /** Clicks the action. */
  async confirm(): Promise<void> {
    await click(this.actionButton)
  }

  /** Clicks the cancel button. */
  async cancel(): Promise<void> {
    await click(this.cancelButton)
  }

  /** Closes it as a user would: with its cancel button, or else Escape. */
  override async close(): Promise<void> {
    if (this.queryPart('cancel')) await this.cancel()
    else await this.pressEscape()
  }
}
