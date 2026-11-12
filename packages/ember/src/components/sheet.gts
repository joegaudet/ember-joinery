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

/** The edge of the screen a sheet comes in from. */
export type SheetSide = 'top' | 'right' | 'bottom' | 'left'

const isOn = (flag: boolean | undefined): boolean => flag !== false

export interface SheetContentSignature {
  Args: DialogContentArgs & {
    /** The sheet, bound by `<Sheet>`. */
    dialog: DialogBlockParams
    /** The edge it comes in from. Default `right`. */
    side?: SheetSide
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

/** The panel, along one edge of the screen behind its overlay, with a close button. */
const SheetContent: TOC<SheetContentSignature> = <template>
  <@dialog.Overlay class="jn-sheet-overlay" @forceMount={{@forceMount}} />
  <@dialog.Content
    class="jn-sheet-content"
    data-side={{if @side @side "right"}}
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
        class="jn-sheet-close"
        type="button"
        data-slot="sheet-close"
        data-test-jn-part="close-button"
        {{on "click" (fn @dialog.setOpen false)}}
      >
        <Icon @icon={{if @closeIcon @closeIcon X}} />
        <VisuallyHidden>{{if @closeLabel @closeLabel (t messages.sheetClose)}}</VisuallyHidden>
      </Button>
    {{/if}}
  </@dialog.Content>
</template>

export interface SheetSectionSignature {
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The title and description, at the top. */
const SheetHeader: TOC<SheetSectionSignature> = <template>
  <div class="jn-sheet-header" data-slot="sheet-header" ...attributes>{{yield}}</div>
</template>

/** The actions, at the bottom. */
const SheetFooter: TOC<SheetSectionSignature> = <template>
  <div class="jn-sheet-footer" data-slot="sheet-footer" ...attributes>{{yield}}</div>
</template>

export interface SheetTextSignature<E extends Element> {
  Args: {
    /** The headless part it styles, bound by `<Sheet>`. */
    base: DialogBlockParams['Title'] | DialogBlockParams['Description']
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** An `<h2>` that names the sheet. */
const SheetTitle: TOC<SheetTextSignature<HTMLHeadingElement>> = <template>
  <@base class="jn-sheet-title jn-font-heading" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

/** A `<p>` that describes the sheet. */
const SheetDescription: TOC<SheetTextSignature<HTMLParagraphElement>> = <template>
  <@base class="jn-sheet-description" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

/** What a `<Sheet>` yields. */
export interface SheetYield {
  /** A `<button>` that opens it. To use your own, such as a `<Button>`, use `trigger`. */
  Trigger: DialogBlockParams['Trigger']
  /** The sheet itself, with its overlay and close button. */
  Content: WithBoundArgs<typeof SheetContent, 'dialog'>
  Header: typeof SheetHeader
  Footer: typeof SheetFooter
  Title: WithBoundArgs<typeof SheetTitle, 'base'>
  Description: WithBoundArgs<typeof SheetDescription, 'base'>
  /** An unstyled `<button>` that closes it. To use your own, use `close`. */
  Close: DialogBlockParams['Close']
  /** Makes your own element or component the trigger: `<Button {{s.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element or component close it: `<Button {{s.close}}>`. */
  close: PartModifier
  isOpen: boolean
  isModal: boolean
  open: () => void
  toggle: () => void
  setOpen: (open: boolean) => void
  returnValue: string
}

export interface SheetSignature {
  Args: Omit<DialogArgs, 'slot'>
  Blocks: { default: [SheetYield] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A dialog that comes in from an edge of the screen, for content that complements the page:
 * shadcn's Sheet, a Dialog by another name and look.
 *
 *   <Sheet as |s|>
 *     <Button @variant="outline" {{s.trigger}}>Open</Button>
 *     <s.Content @side="left">
 *       <s.Header>
 *         <s.Title>Edit profile</s.Title>
 *         <s.Description>Make changes to your profile here.</s.Description>
 *       </s.Header>
 *     </s.Content>
 *   </Sheet>
 */
const Sheet: TOC<SheetSignature> = <template>
  <DialogPrimitive
    @slot="sheet"
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
        Content=(component SheetContent dialog=d)
        Header=SheetHeader
        Footer=SheetFooter
        Title=(component SheetTitle base=d.Title)
        Description=(component SheetDescription base=d.Description)
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

export default Sheet
