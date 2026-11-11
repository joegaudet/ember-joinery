import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { PartModifier } from './part.ts'
import {
  DialogClose,
  DialogContent,
  DialogController,
  DialogDescription,
  DialogOverlay,
  DialogTitle,
  DialogTrigger,
  displayContents,
  type DialogArgs,
} from './-private/dialog.gts'

export {
  DialogController,
  type DialogArgs,
  type DialogContentArgs,
  type DialogRole,
  type InteractOutsideEvent,
} from './-private/dialog.gts'

/** What a `<Dialog>` yields: its parts, their modifiers, and its state. */
export interface DialogBlockParams {
  /** A `<button>` that opens and closes it (`@as` for another tag). */
  Trigger: WithBoundArgs<typeof DialogTrigger, 'part'>
  /** What covers the page behind a modal dialog. A non-modal dialog renders none. */
  Overlay: WithBoundArgs<typeof DialogOverlay, 'dialog'>
  /** The dialog itself, rendered in the top layer while it is open. */
  Content: WithBoundArgs<typeof DialogContent, 'dialog'>
  /** An `<h2>` that names it. */
  Title: WithBoundArgs<typeof DialogTitle, 'part'>
  /** A `<p>` that describes it. */
  Description: WithBoundArgs<typeof DialogDescription, 'part'>
  /** A `<button>` that closes it. */
  Close: WithBoundArgs<typeof DialogClose, 'part'>
  /** Makes your own element or component the trigger: `<Button {{d.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element or component close the dialog: `<Button {{d.close}}>`. */
  close: PartModifier
  /** Makes your own element its title. */
  title: PartModifier
  /** Makes your own element its description. */
  description: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** Whether it is modal. */
  isModal: boolean
  /** Opens it. */
  open: () => void
  /** Opens it if it is closed, and closes it if it is open. */
  toggle: () => void
  /** Opens (`true`) or closes (`false`) it: `(fn d.setOpen false)`. */
  setOpen: (open: boolean) => void
  /** The `value` of the button that submitted a `<form method="dialog">` inside it, or `''`. */
  returnValue: string
}

export interface DialogSignature {
  Args: DialogArgs
  Blocks: { default: [DialogBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A window over the page, as Radix's Dialog (which shadcn's Dialog, Sheet and Alert Dialog are
 * built on), covering ember-primitives' Dialog and Modal too. It renders no box of its own, and
 * yields its parts:
 *
 *   <Dialog as |d|>
 *     <d.Trigger>Edit profile</d.Trigger>
 *     <d.Overlay />
 *     <d.Content>
 *       <d.Title>Edit profile</d.Title>
 *       <d.Description>Make changes to your profile here.</d.Description>
 *       <d.Close>Done</d.Close>
 *     </d.Content>
 *   </Dialog>
 *
 * Its state is its own, or yours with `@open` and `@onOpenChange` (and `@defaultOpen` to start
 * open). While it is open:
 *
 * - the content is in the browser's top layer (above everything, with no portal), and the
 *   overlay under it;
 * - Escape closes it, and so does a press outside the content (the overlay, for a modal one);
 * - focus moves into the content (its first focusable element that isn't a link), and goes back
 *   to the trigger when it closes;
 * - a modal one (the default) keeps focus inside, makes the rest of the page inert as a modal
 *   `<dialog>` does, and the overlay stops the page scrolling.
 *
 * Content and overlay animate out: they stay until a `data-state="closed"` animation ends.
 */
export class Dialog extends Component<DialogSignature> {
  dialog = new DialogController(this)

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
          Close=(component DialogClose part=this.dialog.close)
          trigger=this.dialog.trigger
          close=this.dialog.close
          title=this.dialog.title
          description=this.dialog.description
          isOpen=this.dialog.isOpen
          isModal=this.dialog.isModal
          open=this.dialog.show
          toggle=this.dialog.toggle
          setOpen=this.dialog.setOpen
          returnValue=this.dialog.returnValue
        )
      }}
    </div>
  </template>
}
