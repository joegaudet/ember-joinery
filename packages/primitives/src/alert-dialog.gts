import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { warn } from '@ember/debug'
import type { WithBoundArgs } from '@glint/template'
import { part, type PartModifier } from './part.ts'
import type { FocusOutsideEvent, PointerDownOutsideEvent } from './dismiss.ts'
import {
  buttonType,
  DialogClose,
  DialogContent,
  DialogController,
  DialogDescription,
  DialogOverlay,
  DialogTitle,
  DialogTrigger,
  displayContents,
  type DialogArgs,
  type DialogRole,
  type InteractOutsideEvent,
} from './-private/dialog.gts'

/** What an AlertDialog takes: a Dialog's arguments, but it is always modal. */
export type AlertDialogArgs = Omit<DialogArgs, 'modal'>

/**
 * An AlertDialog's state and parts: a modal Dialog's, with the `alertdialog` role, focus on
 * its Cancel when it opens, and no closing on a press outside, as Radix's AlertDialog.
 */
export class AlertDialogController extends DialogController {
  /** Kept untracked, as the dialog's other elements are. */
  cancelElement: HTMLElement | null = null

  override get isModal(): boolean {
    return true
  }

  override get role(): DialogRole {
    return 'alertdialog'
  }

  override get slot(): string {
    return this.args.slot ?? 'alert-dialog'
  }

  /** Confirms: closes the alert dialog. Put your own action's listener beside it. */
  action: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-slot': `${this.slot}-action`, 'data-test-jn-part': 'action' },
    on: { click: this.hide },
    element: element => buttonType(element),
  }))

  /** Cancels: closes the alert dialog. It has focus when the dialog opens. */
  cancel: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-slot': `${this.slot}-cancel`, 'data-test-jn-part': 'cancel' },
    on: { click: this.hide },
    element: element => {
      this.cancelElement = element
      const restore = buttonType(element)
      return () => {
        restore()
        if (this.cancelElement === element) this.cancelElement = null
      }
    },
  }))

  protected override warnIfUnnamed(element: HTMLElement): void {
    super.warnIfUnnamed(element)
    warn(
      `Joinery: an alert dialog's Content needs a Description, so screen readers can say what ` +
        `it asks.`,
      Boolean(element.ownerDocument.getElementById(this.descriptionId)),
      { id: 'ember-joinery.alert-dialog-description' },
    )
  }

  /** Focus goes to Cancel, the safe choice, rather than to the first button. */
  override onOpenAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
    const cancel = this.cancelElement
    if (event.defaultPrevented || !cancel?.isConnected) return
    event.preventDefault()
    cancel.focus({ preventScroll: true })
  }

  /** It asks for an answer, so a press outside never closes it. */
  override onPointerDownOutside(
    event: PointerDownOutsideEvent,
    handler?: (event: PointerDownOutsideEvent) => void,
  ): void {
    handler?.(event)
    event.preventDefault()
  }

  override onFocusOutside(
    event: FocusOutsideEvent,
    handler?: (event: FocusOutsideEvent) => void,
  ): void {
    handler?.(event)
    event.preventDefault()
  }

  override onInteractOutside(
    event: InteractOutsideEvent,
    handler?: (event: InteractOutsideEvent) => void,
  ): void {
    handler?.(event)
    event.preventDefault()
  }
}

/** What an `<AlertDialog>` yields: a Dialog's parts, with Action and Cancel. */
export interface AlertDialogBlockParams {
  Trigger: WithBoundArgs<typeof DialogTrigger, 'part'>
  Overlay: WithBoundArgs<typeof DialogOverlay, 'dialog'>
  Content: WithBoundArgs<typeof DialogContent, 'dialog'>
  Title: WithBoundArgs<typeof DialogTitle, 'part'>
  Description: WithBoundArgs<typeof DialogDescription, 'part'>
  /** A `<button>` that confirms, and closes the dialog. */
  Action: WithBoundArgs<typeof DialogClose, 'part'>
  /** A `<button>` that cancels, and closes the dialog. It has focus when the dialog opens. */
  Cancel: WithBoundArgs<typeof DialogClose, 'part'>
  trigger: PartModifier
  title: PartModifier
  description: PartModifier
  /** Makes your own element or component the action: `<Button {{d.action}}>`. */
  action: PartModifier
  /** Makes your own element or component the cancel button: `<Button {{d.cancel}}>`. */
  cancel: PartModifier
  isOpen: boolean
  open: () => void
  setOpen: (open: boolean) => void
}

export interface AlertDialogSignature {
  Args: AlertDialogArgs
  Blocks: { default: [AlertDialogBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A modal dialog that interrupts with something important and waits for an answer, as Radix's
 * AlertDialog: a Dialog that is always modal, whose content has the `alertdialog` role, whose
 * Cancel has focus when it opens, and which a press outside doesn't close (Escape and its two
 * buttons do).
 *
 *   <AlertDialog as |d|>
 *     <d.Trigger>Delete account</d.Trigger>
 *     <d.Overlay />
 *     <d.Content>
 *       <d.Title>Are you absolutely sure?</d.Title>
 *       <d.Description>This action cannot be undone.</d.Description>
 *       <d.Cancel>Cancel</d.Cancel>
 *       <d.Action {{on "click" this.delete}}>Continue</d.Action>
 *     </d.Content>
 *   </AlertDialog>
 */
export class AlertDialog extends Component<AlertDialogSignature> {
  dialog = new AlertDialogController(this)

  <template>
    <div
      id={{this.dialog.id}}
      data-test-jn={{this.dialog.slot}}
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Trigger=(component DialogTrigger part=this.dialog.trigger)
          Overlay=(component DialogOverlay dialog=this.dialog)
          Content=(component DialogContent dialog=this.dialog)
          Title=(component DialogTitle part=this.dialog.title)
          Description=(component DialogDescription part=this.dialog.description)
          Action=(component DialogClose part=this.dialog.action)
          Cancel=(component DialogClose part=this.dialog.cancel)
          trigger=this.dialog.trigger
          title=this.dialog.title
          description=this.dialog.description
          action=this.dialog.action
          cancel=this.dialog.cancel
          isOpen=this.dialog.isOpen
          open=this.dialog.show
          setOpen=this.dialog.setOpen
        )
      }}
    </div>
  </template>
}
