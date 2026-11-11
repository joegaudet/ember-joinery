// What Dialog and AlertDialog share: the state, ids and elements their parts tie together, the
// part modifiers, and the part components. dialog.gts and alert-dialog.gts are the public
// modules; this file is bundled into them.
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { warn } from '@ember/debug'
import { on } from '@ember/modifier'
import Modifier, { modifier } from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import type { TOC } from '@ember/component/template-only'
import { As, type TagName } from '../as.gts'
import { controllable, type ControllableArgs } from '../controllable-state.ts'
import {
  dismissable,
  type DismissReason,
  type FocusOutsideEvent,
  type PointerDownOutsideEvent,
} from '../dismiss.ts'
import { focusScope } from '../focus-scope.gts'
import { inertOthers, type Undo } from '../hide-others.ts'
import { idFor } from '../id.ts'
import { topLayer } from '../layer.ts'
import { part, type PartModifier } from '../part.ts'
import { Presence } from '../presence.gts'
import { scrollLock } from '../scroll-lock.ts'

/** The role a dialog's content has: `dialog`, or `alertdialog` for an AlertDialog. */
export type DialogRole = 'dialog' | 'alertdialog'

/** An event outside the content: a pointer going down, or focus moving there. */
export type InteractOutsideEvent = PointerDownOutsideEvent | FocusOutsideEvent

/** What a Dialog (and an AlertDialog) takes. */
export type DialogArgs = ControllableArgs<'open', boolean> & {
  /**
   * Whether it is modal (the default): the page behind is inert and doesn't scroll, focus stays
   * inside, and an overlay covers the page. A non-modal dialog leaves the page usable, and a
   * press or focus outside closes it.
   */
  modal?: boolean
  /** Its name, for its harness (`data-test-jn-name`). */
  name?: string
  /**
   * The name its parts' `data-slot`s start with (`<slot>-trigger`, `<slot>-content`…), which is
   * also its `data-test-jn`. Default `dialog`; Joinery's Sheet passes `sheet`, as shadcn names
   * its parts.
   */
  slot?: string
  /**
   * Called when the dialog closes itself (Escape, a press outside, a close part, or a
   * `<form method="dialog">` inside it), with its `returnValue`: the `value` of the button that
   * submitted that form, or `''`. As ember-primitives' Modal's `@onClose`.
   */
  onClose?: (returnValue: string) => void
}

/** What the Content part takes. */
export interface DialogContentArgs {
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Keep it rendered while closed, for animating it yourself. */
  forceMount?: boolean
  /**
   * Called when the dialog opens, before focus moves in (to its first focusable element that
   * isn't a link). `preventDefault()` to move focus yourself.
   */
  onOpenAutoFocus?: (event: Event) => void
  /**
   * Called when it has closed, before focus goes back to the trigger. `preventDefault()` to send
   * focus somewhere else.
   */
  onCloseAutoFocus?: (event: Event) => void
  /** Escape was pressed. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside it. `preventDefault()` keeps it open. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
  /** Focus moved outside it. `preventDefault()` keeps it open. */
  onFocusOutside?: (event: FocusOutsideEvent) => void
  /** Either of the last two, after its own handler. `preventDefault()` keeps it open. */
  onInteractOutside?: (event: InteractOutsideEvent) => void
}

/** A button of the caller's own, without a `type`, becomes `type="button"`, as Radix's parts do. */
export function buttonType(element: Element): () => void {
  if (!(element instanceof HTMLButtonElement) || element.hasAttribute('type')) return () => {}
  element.type = 'button'
  return () => element.removeAttribute('type')
}

/** `display: contents` through the CSSOM, which a strict Content Security Policy allows. */
export const displayContents = modifier((element: HTMLElement) => {
  element.style.setProperty('display', 'contents')
})

/**
 * One dialog's state and what its parts share: whether it is open, its ids, the elements that
 * render it, and the part modifiers. `Dialog` makes one; `AlertDialog` makes the subclass.
 */
export class DialogController {
  readonly #owner: { readonly args: DialogArgs }
  readonly openState
  /** Kept untracked: the parts that read them render after these have. */
  triggerElement: HTMLElement | null = null
  contentElement: HTMLElement | null = null
  overlayElement: HTMLElement | null = null

  /** The `value` of the button that last submitted a `<form method="dialog">` inside it. */
  @tracked returnValue = ''

  #interactedOutside = false
  #pointerDownOutside = false

  constructor(owner: { readonly args: DialogArgs }) {
    this.#owner = owner
    this.openState = controllable(owner, 'open', false)
  }

  get args(): DialogArgs {
    return this.#owner.args
  }

  get isOpen(): boolean {
    return this.openState.value
  }

  get state(): 'open' | 'closed' {
    return this.isOpen ? 'open' : 'closed'
  }

  get isModal(): boolean {
    return this.args.modal ?? true
  }

  /** Whether focus is kept inside: while a modal dialog is open (not while it animates out). */
  get trapsFocus(): boolean {
    return this.isModal && this.isOpen
  }

  get role(): DialogRole {
    return 'dialog'
  }

  get slot(): string {
    return this.args.slot ?? 'dialog'
  }

  get id(): string {
    return idFor(this)
  }

  get contentId(): string {
    return idFor(this, 'content')
  }

  get titleId(): string {
    return idFor(this, 'title')
  }

  get descriptionId(): string {
    return idFor(this, 'description')
  }

  /** Where a wheel or a finger still scrolls while the overlay locks the page. */
  scrollShards = (): Array<Element | null> => [this.contentElement]

  setOpen = (open: boolean): void => {
    const was = this.isOpen
    if (open && !was) this.returnValue = ''
    this.openState.set(open)
    if (was && !open) this.args.onClose?.(this.returnValue)
  }

  show = (): void => this.setOpen(true)
  hide = (): void => this.setOpen(false)
  toggle = (): void => this.setOpen(!this.isOpen)
  dismiss = (_reason: DismissReason): void => this.hide()

  // ----- The parts ---------------------------------------------------------------------------

  trigger: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      'aria-haspopup': 'dialog',
      'aria-expanded': String(this.isOpen),
      'aria-controls': this.isOpen ? this.contentId : undefined,
      'data-state': this.state,
      'data-slot': `${this.slot}-trigger`,
      'data-test-jn-part': 'trigger',
    },
    on: { click: this.toggle },
    element: element => {
      this.triggerElement = element
      const restore = buttonType(element)
      return () => {
        restore()
        if (this.triggerElement === element) this.triggerElement = null
      }
    },
  }))

  close: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-slot': `${this.slot}-close`, 'data-test-jn-part': 'close' },
    on: { click: this.hide },
    element: buttonType,
  }))

  title: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.titleId,
      'data-slot': `${this.slot}-title`,
      'data-test-jn-part': 'title',
    },
  }))

  description: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.descriptionId,
      'data-slot': `${this.slot}-description`,
      'data-test-jn-part': 'description',
    },
  }))

  overlay: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      'data-state': this.state,
      'data-slot': `${this.slot}-overlay`,
      'data-test-jn-part': 'overlay',
      'data-test-jn-owner': this.id,
    },
    element: element => {
      this.overlayElement = element
      // Radix's overlay takes the pointer while a modal content turns it off everywhere else, so
      // a press on it is a press outside the content.
      const style = element.style
      const previous = style.getPropertyValue('pointer-events')
      style.setProperty('pointer-events', 'auto')
      return () => {
        if (previous) style.setProperty('pointer-events', previous)
        else style.removeProperty('pointer-events')
        if (this.overlayElement === element) this.overlayElement = null
      }
    },
  }))

  content: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.contentId,
      role: this.role,
      'aria-modal': this.isModal ? 'true' : undefined,
      'aria-labelledby': this.titleId,
      'aria-describedby': this.descriptionId,
      'data-state': this.state,
      'data-slot': `${this.slot}-content`,
      'data-test-jn-part': 'content',
      'data-test-jn-owner': this.id,
    },
    element: element => {
      this.contentElement = element
      this.warnIfUnnamed(element)
      return () => {
        if (this.contentElement === element) this.contentElement = null
      }
    },
  }))

  /** As Radix does, says so in development when the content has no title to name it. */
  protected warnIfUnnamed(element: HTMLElement): void {
    const document = element.ownerDocument
    warn(
      `Joinery: a dialog's Content needs a Title, so screen readers can name it. To hide the ` +
        `title, put it in a <VisuallyHidden> (@ember-joinery/primitives/visually-hidden).`,
      Boolean(document.getElementById(this.titleId)),
      { id: 'ember-joinery.dialog-title' },
    )
  }

  // ----- What the content does, as Radix's modal and non-modal contents do ------------------

  onOpenAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
  }

  onCloseAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
    const interacted = this.#interactedOutside
    this.#interactedOutside = false
    this.#pointerDownOutside = false
    if (event.defaultPrevented) return
    const trigger = this.triggerElement?.isConnected ? this.triggerElement : null
    if (this.isModal) {
      // To the trigger; without one, the focus scope returns focus to where it was.
      if (!trigger) return
      event.preventDefault()
      trigger.focus()
    } else {
      // Unless the user went somewhere else, back to the trigger.
      if (!interacted) trigger?.focus()
      event.preventDefault()
    }
  }

  onPointerDownOutside(
    event: PointerDownOutsideEvent,
    handler?: (event: PointerDownOutsideEvent) => void,
  ): void {
    handler?.(event)
    if (event.defaultPrevented || !this.isModal) return
    // A right click (or Ctrl and a click, on a Mac) opens a menu; it doesn't close the dialog.
    const original = event.detail.originalEvent
    if (original.button === 2 || (original.button === 0 && original.ctrlKey)) event.preventDefault()
  }

  onFocusOutside(event: FocusOutsideEvent, handler?: (event: FocusOutsideEvent) => void): void {
    handler?.(event)
    // Focus stays inside a modal dialog, so focus outside never closes one.
    if (!event.defaultPrevented && this.isModal) event.preventDefault()
  }

  onInteractOutside(
    event: InteractOutsideEvent,
    handler?: (event: InteractOutsideEvent) => void,
  ): void {
    handler?.(event)
    if (this.isModal) return
    const type = event.detail.originalEvent.type
    if (!event.defaultPrevented) {
      this.#interactedOutside = true
      if (type === 'pointerdown') this.#pointerDownOutside = true
    }
    // The trigger toggles the dialog itself, so a press on it isn't a dismissal first.
    const target = event.target
    if (target instanceof Node && this.triggerElement?.contains(target)) event.preventDefault()
    // A press outside moves focus outside too; the press decided already.
    if (type === 'focusin' && this.#pointerDownOutside) event.preventDefault()
  }

  /** A `<form method="dialog">` inside closes it, with the submitting button's `value`. */
  onSubmit = (event: SubmitEvent): void => {
    const form = event.target
    if (!(form instanceof HTMLFormElement) || form.method !== 'dialog') return
    const submitter = event.submitter
    this.returnValue =
      submitter instanceof HTMLButtonElement || submitter instanceof HTMLInputElement
        ? submitter.value
        : ''
    this.hide()
  }
}

// ----- The part components -------------------------------------------------------------------

export interface DialogPartSignature<E extends Element> {
  Args: {
    /** The part's modifier, bound by the dialog. */
    part: PartModifier
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** A `<button type="button">`, or `@as`, that opens and closes the dialog. */
export const DialogTrigger: TOC<DialogPartSignature<HTMLButtonElement | HTMLAnchorElement>> =
  <template>
    <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
  </template>

/** A `<button type="button">`, or `@as`, that closes the dialog. */
export const DialogClose: TOC<DialogPartSignature<HTMLButtonElement | HTMLAnchorElement>> =
  <template>
    <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
  </template>

/** The `<h2>`, or `@as`, that names the dialog (its content's `aria-labelledby`). */
export const DialogTitle: TOC<DialogPartSignature<HTMLHeadingElement>> = <template>
  <As @as={{@as}} @tag="h2" ...attributes {{@part}}>{{yield}}</As>
</template>

/** The `<p>`, or `@as`, that describes the dialog (its content's `aria-describedby`). */
export const DialogDescription: TOC<DialogPartSignature<HTMLParagraphElement>> = <template>
  <As @as={{@as}} @tag="p" ...attributes {{@part}}>{{yield}}</As>
</template>

export interface DialogOverlaySignature {
  Args: {
    dialog: DialogController
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Keep it rendered while closed, for animating it yourself. */
    forceMount?: boolean
  }
  Element: HTMLDivElement
}

/**
 * What covers the page behind a modal dialog: in the top layer, below the content, taking the
 * pointer (a press on it closes the dialog), and locking the page's scroll while it is there. A
 * non-modal dialog has none, as in Radix.
 */
export const DialogOverlay: TOC<DialogOverlaySignature> = <template>
  {{#if @dialog.isModal}}
    <Presence @present={{@dialog.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{presence.ref}}
        {{@dialog.overlay}}
        {{topLayer}}
        {{scrollLock inside=@dialog.scrollShards}}
      />
    </Presence>
  {{/if}}
</template>

interface InertOutsideSignature {
  Element: HTMLElement
  Args: { Named: { dialog: DialogController } }
}

/** While its dialog is modal, makes everything but the content and the overlay inert. */
class InertOutside extends Modifier<InertOutsideSignature> {
  #undo: Undo | undefined
  #installed = false

  override modify(element: HTMLElement, _: [], { dialog }: { dialog: DialogController }): void {
    if (!this.#installed) {
      this.#installed = true
      registerDestructor(this, () => this.#release())
    }
    if (!dialog.isModal) return this.#release()
    this.#undo ??= inertOthers([element, dialog.overlayElement])
  }

  #release(): void {
    this.#undo?.()
    this.#undo = undefined
  }
}

export interface DialogContentSignature {
  Args: DialogContentArgs & { dialog: DialogController }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The dialog itself: in the top layer while open (and while it animates out), with its role,
 * its title and description tied to it, Escape and presses outside closing it, and focus moving
 * in when it opens and back when it closes. A modal one also keeps focus inside and makes the
 * rest of the page inert, as a modal `<dialog>` does.
 */
export class DialogContent extends Component<DialogContentSignature> {
  get dialog(): DialogController {
    return this.args.dialog
  }

  onOpenAutoFocus = (event: Event) => this.dialog.onOpenAutoFocus(event, this.args.onOpenAutoFocus)
  onCloseAutoFocus = (event: Event) =>
    this.dialog.onCloseAutoFocus(event, this.args.onCloseAutoFocus)
  onEscapeKeyDown = (event: KeyboardEvent) => this.args.onEscapeKeyDown?.(event)
  onPointerDownOutside = (event: PointerDownOutsideEvent) =>
    this.dialog.onPointerDownOutside(event, this.args.onPointerDownOutside)
  onFocusOutside = (event: FocusOutsideEvent) =>
    this.dialog.onFocusOutside(event, this.args.onFocusOutside)
  onInteractOutside = (event: InteractOutsideEvent) =>
    this.dialog.onInteractOutside(event, this.args.onInteractOutside)

  <template>
    <Presence @present={{@dialog.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{presence.ref}}
        {{@dialog.content}}
        {{topLayer}}
        {{InertOutside dialog=@dialog}}
        {{dismissable
          onDismiss=@dialog.dismiss
          onEscapeKeyDown=this.onEscapeKeyDown
          onPointerDownOutside=this.onPointerDownOutside
          onFocusOutside=this.onFocusOutside
          onInteractOutside=this.onInteractOutside
          disableOutsidePointerEvents=@dialog.isModal
        }}
        {{focusScope
          trapped=@dialog.trapsFocus
          loop=true
          onMountAutoFocus=this.onOpenAutoFocus
          onUnmountAutoFocus=this.onCloseAutoFocus
        }}
        {{on "submit" @dialog.onSubmit}}
      >{{yield}}</As>
    </Presence>
  </template>
}
