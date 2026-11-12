import { fn, hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { X } from 'lucide'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  Dialog as DialogPrimitive,
  type DialogArgs,
  type DialogBlockParams,
  type DialogContentArgs,
} from '@ember-joinery/primitives/dialog'
import type { PartModifier } from '@ember-joinery/primitives/part'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Button from './button.gts'
import Icon, { type IconNode } from './icon.gts'
import { t } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

/** Whether an optional flag that defaults to on is on. */
const isOn = (flag: boolean | undefined): boolean => flag !== false

export interface DialogContentSignature {
  Args: DialogContentArgs & {
    /** The dialog, bound by `<Dialog>`. */
    dialog: DialogBlockParams
    /** Show the close button in the corner. Default `true`. */
    showCloseButton?: boolean
    /** The close button's name for screen readers. Default `Close`. */
    closeLabel?: string
    /** The close button's icon: one from `lucide`. Default lucide's `x` (`XIcon`). */
    closeIcon?: IconNode
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The dialog, centred over the page behind its overlay, with a close button in its corner. It
 * renders upstream's DialogPortal: the overlay, then the content, in the top layer.
 */
const DialogContent: TOC<DialogContentSignature> = <template>
  <@dialog.Overlay class="jn-dialog-overlay" @forceMount={{@forceMount}} />
  <@dialog.Content
    class="jn-dialog-content"
    @as={{@as}}
    @forceMount={{@forceMount}}
    @onOpenAutoFocus={{@onOpenAutoFocus}}
    @onCloseAutoFocus={{@onCloseAutoFocus}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    ...attributes
  >
    {{yield}}
    {{#if (isOn @showCloseButton)}}
      <Button
        @variant="ghost"
        @size="icon-sm"
        class="jn-dialog-close"
        type="button"
        data-slot="dialog-close"
        data-test-jn-part="close-button"
        {{on "click" (fn @dialog.setOpen false)}}
      >
        <Icon @icon={{if @closeIcon @closeIcon X}} />
        <VisuallyHidden>{{if @closeLabel @closeLabel (t messages.dialogClose)}}</VisuallyHidden>
      </Button>
    {{/if}}
  </@dialog.Content>
</template>

export interface DialogSectionSignature {
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The title and description, stacked. */
const DialogHeader: TOC<DialogSectionSignature> = <template>
  <div class="jn-dialog-header" data-slot="dialog-header" ...attributes>{{yield}}</div>
</template>

export interface DialogFooterSignature {
  Args: {
    /** The dialog's close modifier, bound by `<Dialog>`. */
    close: PartModifier
    /** Add a Close button after the block. Default `false`. */
    showCloseButton?: boolean
    /** That button's text. Default `Close`. */
    closeLabel?: string
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The actions: stacked on a phone, in a row at the end from `sm` up. */
const DialogFooter: TOC<DialogFooterSignature> = <template>
  <div class="jn-dialog-footer" data-slot="dialog-footer" ...attributes>
    {{yield}}
    {{#if @showCloseButton}}
      <Button @variant="outline" {{@close}}>{{if
          @closeLabel
          @closeLabel
          (t messages.dialogClose)
        }}</Button>
    {{/if}}
  </div>
</template>

export interface DialogTextSignature<E extends Element> {
  Args: {
    /** The headless part it styles, bound by `<Dialog>`. */
    base: DialogBlockParams['Title'] | DialogBlockParams['Description']
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** An `<h2>` that names the dialog. */
const DialogTitle: TOC<DialogTextSignature<HTMLHeadingElement>> = <template>
  <@base class="jn-dialog-title jn-font-heading" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

/** A `<p>` that describes the dialog. */
const DialogDescription: TOC<DialogTextSignature<HTMLParagraphElement>> = <template>
  <@base class="jn-dialog-description" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

/** What a `<Dialog>` yields. */
export interface DialogYield {
  /** A `<button>` that opens it. To use your own, such as a `<Button>`, use `trigger`. */
  Trigger: DialogBlockParams['Trigger']
  /** The dialog itself, with its overlay and close button. */
  Content: WithBoundArgs<typeof DialogContent, 'dialog'>
  Header: typeof DialogHeader
  Footer: WithBoundArgs<typeof DialogFooter, 'close'>
  Title: WithBoundArgs<typeof DialogTitle, 'base'>
  Description: WithBoundArgs<typeof DialogDescription, 'base'>
  /** An unstyled `<button>` that closes it. To use your own, use `close`. */
  Close: DialogBlockParams['Close']
  /** Makes your own element or component the trigger: `<Button {{d.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element or component close it: `<Button {{d.close}}>`. */
  close: PartModifier
  isOpen: boolean
  isModal: boolean
  open: () => void
  toggle: () => void
  setOpen: (open: boolean) => void
  returnValue: string
}

export interface DialogSignature {
  Args: Omit<DialogArgs, 'slot'>
  Blocks: { default: [DialogYield] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A window overlaid on the page, rendering the content underneath inert: shadcn's Dialog, on
 * the headless one in `@ember-joinery/primitives/dialog`.
 *
 *   <Dialog @name="edit-profile" as |d|>
 *     <Button @variant="outline" {{d.trigger}}>Edit profile</Button>
 *     <d.Content>
 *       <d.Header>
 *         <d.Title>Edit profile</d.Title>
 *         <d.Description>Make changes to your profile here.</d.Description>
 *       </d.Header>
 *       <d.Footer>
 *         <Button @variant="outline" {{d.close}}>Cancel</Button>
 *         <Button>Save changes</Button>
 *       </d.Footer>
 *     </d.Content>
 *   </Dialog>
 */
const Dialog: TOC<DialogSignature> = <template>
  <DialogPrimitive
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @modal={{@modal}}
    @name={{@name}}
    @onClose={{@onClose}}
    ...attributes
    as |d|
  >
    {{yield
      (hash
        Trigger=d.Trigger
        Content=(component DialogContent dialog=d)
        Header=DialogHeader
        Footer=(component DialogFooter close=d.close)
        Title=(component DialogTitle base=d.Title)
        Description=(component DialogDescription base=d.Description)
        Close=d.Close
        trigger=d.trigger
        close=d.close
        isOpen=d.isOpen
        isModal=d.isModal
        open=d.open
        toggle=d.toggle
        setOpen=d.setOpen
        returnValue=d.returnValue
      )
    }}
  </DialogPrimitive>
</template>

export default Dialog
