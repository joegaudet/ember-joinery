import { hash } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  AlertDialog as AlertDialogPrimitive,
  type AlertDialogArgs,
  type AlertDialogBlockParams,
} from '@ember-joinery/primitives/alert-dialog'
import type { DialogContentArgs } from '@ember-joinery/primitives/dialog'
import type { PartModifier } from '@ember-joinery/primitives/part'
import Button, { type ButtonSize, type ButtonVariant } from './button.gts'

/** How big an alert dialog is. */
export type AlertDialogSize = 'default' | 'sm'

export interface AlertDialogContentSignature {
  Args: DialogContentArgs & {
    /** The alert dialog, bound by `<AlertDialog>`. */
    dialog: AlertDialogBlockParams
    /** `sm` is narrower, and puts its two buttons side by side. Default `default`. */
    size?: AlertDialogSize
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The alert dialog, centred over the page behind its overlay. */
const AlertDialogContent: TOC<AlertDialogContentSignature> = <template>
  <@dialog.Overlay class="jn-alert-dialog-overlay" @forceMount={{@forceMount}} />
  <@dialog.Content
    class="jn-alert-dialog-content group/alert-dialog-content"
    data-size={{if @size @size "default"}}
    @as={{@as}}
    @forceMount={{@forceMount}}
    @onOpenAutoFocus={{@onOpenAutoFocus}}
    @onCloseAutoFocus={{@onCloseAutoFocus}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    ...attributes
  >{{yield}}</@dialog.Content>
</template>

export interface AlertDialogSectionSignature {
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The media, title and description: centred, and from `sm` up, at the start. */
const AlertDialogHeader: TOC<AlertDialogSectionSignature> = <template>
  <div class="jn-alert-dialog-header" data-slot="alert-dialog-header" ...attributes>{{yield}}</div>
</template>

/** The two buttons: stacked on a phone, in a row at the end from `sm` up. */
const AlertDialogFooter: TOC<AlertDialogSectionSignature> = <template>
  <div class="jn-alert-dialog-footer" data-slot="alert-dialog-footer" ...attributes>{{yield}}</div>
</template>

/** An icon or image above the title. */
const AlertDialogMedia: TOC<AlertDialogSectionSignature> = <template>
  <div class="jn-alert-dialog-media" data-slot="alert-dialog-media" ...attributes>{{yield}}</div>
</template>

export interface AlertDialogTextSignature<E extends Element> {
  Args: {
    /** The headless part it styles, bound by `<AlertDialog>`. */
    base: AlertDialogBlockParams['Title'] | AlertDialogBlockParams['Description']
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** An `<h2>` that names the alert dialog. */
const AlertDialogTitle: TOC<AlertDialogTextSignature<HTMLHeadingElement>> = <template>
  <@base class="jn-alert-dialog-title jn-font-heading" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

/** A `<p>` that says what the alert dialog asks. */
const AlertDialogDescription: TOC<AlertDialogTextSignature<HTMLParagraphElement>> = <template>
  <@base class="jn-alert-dialog-description" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

export interface AlertDialogButtonSignature {
  Args: {
    /** The part's modifier, bound by `<AlertDialog>`. */
    part: PartModifier
    /** How it looks. Default `default` for the action, `outline` for cancel. */
    variant?: ButtonVariant
    /** Default `default`. */
    size?: ButtonSize
    /** Its name, for `ButtonHarness`. */
    name?: string
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement | HTMLAnchorElement
}

/** A Button that confirms, and closes the alert dialog. Listen for its click to act. */
const AlertDialogAction: TOC<AlertDialogButtonSignature> = <template>
  <Button
    @variant={{if @variant @variant "default"}}
    @size={{if @size @size "default"}}
    @name={{@name}}
    class="jn-alert-dialog-action"
    ...attributes
    {{@part}}
  >{{yield}}</Button>
</template>

/** A Button that cancels, and closes the alert dialog. It has focus when the dialog opens. */
const AlertDialogCancel: TOC<AlertDialogButtonSignature> = <template>
  <Button
    @variant={{if @variant @variant "outline"}}
    @size={{if @size @size "default"}}
    @name={{@name}}
    class="jn-alert-dialog-cancel"
    ...attributes
    {{@part}}
  >{{yield}}</Button>
</template>

/** What an `<AlertDialog>` yields. */
export interface AlertDialogYield {
  /** A `<button>` that opens it. To use your own, such as a `<Button>`, use `trigger`. */
  Trigger: AlertDialogBlockParams['Trigger']
  Content: WithBoundArgs<typeof AlertDialogContent, 'dialog'>
  Header: typeof AlertDialogHeader
  Footer: typeof AlertDialogFooter
  Media: typeof AlertDialogMedia
  Title: WithBoundArgs<typeof AlertDialogTitle, 'base'>
  Description: WithBoundArgs<typeof AlertDialogDescription, 'base'>
  Action: WithBoundArgs<typeof AlertDialogAction, 'part'>
  Cancel: WithBoundArgs<typeof AlertDialogCancel, 'part'>
  /** Makes your own element or component the trigger: `<Button {{d.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element or component the action. */
  action: PartModifier
  /** Makes your own element or component the cancel button. */
  cancel: PartModifier
  isOpen: boolean
  open: () => void
  setOpen: (open: boolean) => void
}

export interface AlertDialogSignature {
  Args: Omit<AlertDialogArgs, 'slot'>
  Blocks: { default: [AlertDialogYield] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A modal dialog that interrupts with something important and waits for an answer: shadcn's
 * Alert Dialog, on the headless one in `@ember-joinery/primitives/alert-dialog`. Its Cancel has
 * focus when it opens, and a press outside doesn't close it.
 *
 *   <AlertDialog as |d|>
 *     <Button @variant="outline" {{d.trigger}}>Show Dialog</Button>
 *     <d.Content>
 *       <d.Header>
 *         <d.Title>Are you absolutely sure?</d.Title>
 *         <d.Description>This action cannot be undone.</d.Description>
 *       </d.Header>
 *       <d.Footer>
 *         <d.Cancel>Cancel</d.Cancel>
 *         <d.Action {{on "click" this.delete}}>Continue</d.Action>
 *       </d.Footer>
 *     </d.Content>
 *   </AlertDialog>
 */
const AlertDialog: TOC<AlertDialogSignature> = <template>
  <AlertDialogPrimitive
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @name={{@name}}
    @onClose={{@onClose}}
    ...attributes
    as |d|
  >
    {{yield
      (hash
        Trigger=d.Trigger
        Content=(component AlertDialogContent dialog=d)
        Header=AlertDialogHeader
        Footer=AlertDialogFooter
        Media=AlertDialogMedia
        Title=(component AlertDialogTitle base=d.Title)
        Description=(component AlertDialogDescription base=d.Description)
        Action=(component AlertDialogAction part=d.action)
        Cancel=(component AlertDialogCancel part=d.cancel)
        trigger=d.trigger
        action=d.action
        cancel=d.cancel
        isOpen=d.isOpen
        open=d.open
        setOpen=d.setOpen
      )
    }}
  </AlertDialogPrimitive>
</template>

export default AlertDialog
