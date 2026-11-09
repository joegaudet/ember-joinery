import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import type { AnchorData, AnchorOptions } from './anchor/index.ts'
import { controllable, type ControllableArgs } from './controllable-state.ts'
import {
  dismissable,
  type DismissReason,
  type FocusOutsideEvent,
  type PointerDownOutsideEvent,
} from './dismiss.ts'
import { addFocusGuards, createFocusScope, type FocusScopeHandle } from './focus-scope.gts'
import { idFor } from './id.ts'
import { topLayer } from './layer.ts'
import { part, type PartModifier } from './part.ts'
import { Presence } from './presence.gts'
import {
  ElementRef,
  PlacedData,
  PopperArrow,
  anchorContent,
  buttonType,
  displayContents,
  ensureId,
  exposeProperties,
  popperOptions,
  type PopperContentArgs,
} from './-private/popper.gts'

/** ember-primitives' Popover arguments, which every Content of the popover takes from its root. */
type PopoverPositionArgs = Pick<
  PopperContentArgs,
  'placement' | 'offsetOptions' | 'flipOptions' | 'shiftOptions' | 'middleware' | 'strategy'
>

/** What a `<Popover>` takes. */
export type PopoverArgs = ControllableArgs<'open', boolean> &
  PopoverPositionArgs & {
    /**
     * Whether it is modal: focus stays inside, and the rest of the page ignores the pointer
     * until it closes. Default `false`.
     */
    modal?: boolean
    /** Its name, for `PopoverHarness` (`data-test-jn-name`). */
    name?: string
  }

/** What a popover's Content takes: where it goes (Radix's Popper arguments) and what it does. */
export interface PopoverContentArgs extends PopperContentArgs {
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Keep it rendered while closed, for animating it yourself. */
  forceMount?: boolean
  /**
   * Called when it opens, before focus moves in (to its first focusable element that isn't a
   * link, or the content itself). `preventDefault()` to move focus yourself.
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
  onInteractOutside?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void
}

/** Radix's Popper defaults for a popover's content: below its trigger, centred, touching it. */
const CONTENT_DEFAULTS: PopperContentArgs = { side: 'bottom', align: 'center', sideOffset: 0 }

interface LabelSignature {
  Element: HTMLElement
  Args: { Named: { labelledBy: string | undefined; describedBy: string | undefined } }
}

/**
 * Names the content by its Title (or else its trigger) and describes it by its Description,
 * unless the caller named or described it themselves (`aria-label`, `aria-labelledby`,
 * `aria-describedby` on the Content).
 */
class LabelContent extends Modifier<LabelSignature> {
  #ownName: boolean | undefined
  #ownDescription: boolean | undefined

  override modify(
    element: HTMLElement,
    _: [],
    { labelledBy, describedBy }: LabelSignature['Args']['Named'],
  ): void {
    this.#ownName ??= element.hasAttribute('aria-label') || element.hasAttribute('aria-labelledby')
    this.#ownDescription ??= element.hasAttribute('aria-describedby')
    if (!this.#ownName) set(element, 'aria-labelledby', labelledBy)
    if (!this.#ownDescription) set(element, 'aria-describedby', describedBy)
  }
}

function set(element: Element, name: string, value: string | undefined): void {
  if (value) element.setAttribute(name, value)
  else element.removeAttribute(name)
}

interface ContentFocusSignature {
  Element: HTMLElement
  Args: {
    Named: {
      enabled: boolean
      trapped: boolean
      onMountAutoFocus: (event: Event) => void
      onUnmountAutoFocus: (event: Event) => void
    }
  }
}

/**
 * The content's focus scope, as Radix's popover has it: focus moves in when it opens, goes
 * round inside (`loop`), stays inside while modal, and goes back when it closes; and focus
 * guards at the ends of `<body>` meanwhile. Turned off while a force-mounted content is closed.
 * One scope for the content's life: changing an argument updates it rather than starting over.
 */
class ContentFocus extends Modifier<ContentFocusSignature> {
  #scope: FocusScopeHandle | undefined
  #releaseGuards: (() => void) | undefined
  #addedTabindex = false
  #element: HTMLElement | undefined

  override modify(
    element: HTMLElement,
    _: [],
    {
      enabled,
      trapped,
      onMountAutoFocus,
      onUnmountAutoFocus,
    }: ContentFocusSignature['Args']['Named'],
  ): void {
    if (!this.#element) {
      this.#element = element
      registerDestructor(this, () => this.#stop())
    }
    const options = { trapped, loop: true, onMountAutoFocus, onUnmountAutoFocus }
    if (!enabled) return this.#stop()
    if (this.#scope) return this.#scope.update(options)
    this.#addedTabindex = !element.hasAttribute('tabindex')
    if (this.#addedTabindex) element.setAttribute('tabindex', '-1')
    this.#releaseGuards = addFocusGuards()
    this.#scope = createFocusScope(element, options)
  }

  #stop(): void {
    this.#scope?.destroy()
    this.#scope = undefined
    this.#releaseGuards?.()
    this.#releaseGuards = undefined
    if (this.#addedTabindex) this.#element?.removeAttribute('tabindex')
    this.#addedTabindex = false
  }
}

// ----- The parts ---------------------------------------------------------------------------

export interface PopoverPartSignature<E extends Element> {
  Args: {
    /** The part's modifier, bound by the popover. */
    part: PartModifier
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** A `<button type="button">`, or `@as`, that opens and closes the popover. */
const PopoverTrigger: TOC<PopoverPartSignature<HTMLButtonElement>> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
</template>

/** An element to place the content against instead of the trigger: Radix's `Popover.Anchor`. */
const PopoverAnchor: TOC<PopoverPartSignature<HTMLDivElement>> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@part}}>{{yield}}</As>
</template>

/** A `<button type="button">`, or `@as`, that closes the popover. */
const PopoverClose: TOC<PopoverPartSignature<HTMLButtonElement>> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
</template>

/** An `<h2>`, or `@as`, that names the content (its `aria-labelledby`). */
const PopoverTitle: TOC<PopoverPartSignature<HTMLHeadingElement>> = <template>
  <As @as={{@as}} @tag="h2" ...attributes {{@part}}>{{yield}}</As>
</template>

/** A `<p>`, or `@as`, that describes the content (its `aria-describedby`). */
const PopoverDescription: TOC<PopoverPartSignature<HTMLParagraphElement>> = <template>
  <As @as={{@as}} @tag="p" ...attributes {{@part}}>{{yield}}</As>
</template>

export interface PopoverContentSignature {
  Args: PopoverContentArgs & {
    /** @internal Bound by the popover. */
    popover: Popover
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The popover itself: in the top layer while it is open (and while it animates out), placed
 * against its trigger (or Anchor), flipping to stay in view, with Escape and presses outside
 * closing it and focus moving in when it opens and back when it closes.
 */
class PopoverContent extends Component<PopoverContentSignature> {
  get popover(): Popover {
    return this.args.popover
  }

  get anchorOptions(): AnchorOptions {
    const { popover } = this
    return popperOptions(this.args, popover.args, CONTENT_DEFAULTS, {
      arrow: popover.arrowRef.value,
      setData: popover.placed.set,
    })
  }

  /** Focus moves in and is kept while it is shown; a force-mounted content that is closed is left alone. */
  get scopesFocus(): boolean {
    return this.popover.isOpen || !this.args.forceMount
  }

  onOpenAutoFocus = (event: Event): void => this.args.onOpenAutoFocus?.(event)
  onCloseAutoFocus = (event: Event): void =>
    this.popover.closeAutoFocus(event, this.args.onCloseAutoFocus)
  onEscapeKeyDown = (event: KeyboardEvent): void => this.args.onEscapeKeyDown?.(event)
  onPointerDownOutside = (event: PointerDownOutsideEvent): void =>
    this.popover.pointerDownOutside(event, this.args.onPointerDownOutside)
  onFocusOutside = (event: FocusOutsideEvent): void =>
    this.popover.focusOutside(event, this.args.onFocusOutside)
  onInteractOutside = (event: PointerDownOutsideEvent | FocusOutsideEvent): void =>
    this.popover.interactOutside(event, this.args.onInteractOutside)

  <template>
    <Presence @present={{@popover.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{presence.ref}}
        {{@popover.content}}
        {{LabelContent labelledBy=@popover.labelledBy describedBy=@popover.describedBy}}
        {{topLayer}}
        {{anchorContent @popover.reference this.anchorOptions}}
        {{dismissable
          enabled=@popover.isOpen
          onDismiss=@popover.dismiss
          onEscapeKeyDown=this.onEscapeKeyDown
          onPointerDownOutside=this.onPointerDownOutside
          onFocusOutside=this.onFocusOutside
          onInteractOutside=this.onInteractOutside
          disableOutsidePointerEvents=@popover.isModal
          inside=@popover.inside
        }}
        {{ContentFocus
          enabled=this.scopesFocus
          trapped=@popover.trapsFocus
          onMountAutoFocus=this.onOpenAutoFocus
          onUnmountAutoFocus=this.onCloseAutoFocus
        }}
      >{{yield}}</As>
    </Presence>
  </template>
}

export interface PopoverArrowSignature {
  Args: {
    /** @internal Bound by the popover. */
    popover: Popover
    /** Its width, in pixels. Default 10. */
    width?: number
    /** Its height, in pixels. Default 5. */
    height?: number
  }
  /** A shape of your own instead of the triangle, inside the `<svg>`. */
  Blocks: { default: [] }
  Element: SVGSVGElement
}

/** Radix's `Popover.Arrow`: an `<svg>` triangle on the content's edge, pointing at the trigger. */
const PopoverArrow: TOC<PopoverArrowSignature> = <template>
  {{#if (has-block)}}
    <PopperArrow @arrow={{@popover.arrowRef}} @width={{@width}} @height={{@height}} ...attributes>
      {{yield}}
    </PopperArrow>
  {{else}}
    <PopperArrow @arrow={{@popover.arrowRef}} @width={{@width}} @height={{@height}} ...attributes />
  {{/if}}
</template>

// ----- The popover ---------------------------------------------------------------------------

/** What a `<Popover>` yields: its parts, their modifiers, where its content went, and its state. */
export interface PopoverBlockParams {
  /** A `<button>` that opens and closes it (`@as` for another tag). */
  Trigger: WithBoundArgs<typeof PopoverTrigger, 'part'>
  /** Something to place the content against instead of the trigger. */
  Anchor: WithBoundArgs<typeof PopoverAnchor, 'part'>
  /** The popover itself, in the top layer while it is open. */
  Content: WithBoundArgs<typeof PopoverContent, 'popover'>
  /** A `<button>` that closes it. */
  Close: WithBoundArgs<typeof PopoverClose, 'part'>
  /** An arrow on the content's edge, pointing at the trigger. Put it inside the Content. */
  Arrow: WithBoundArgs<typeof PopoverArrow, 'popover'>
  /** An `<h2>` that names the content. */
  Title: WithBoundArgs<typeof PopoverTitle, 'part'>
  /** A `<p>` that describes the content. */
  Description: WithBoundArgs<typeof PopoverDescription, 'part'>
  /** Makes your own element or component the trigger: `<Button {{p.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element the anchor. */
  anchor: PartModifier
  /** Makes your own element or component close the popover. */
  close: PartModifier
  /** Makes your own element the title. */
  title: PartModifier
  /** Makes your own element the description. */
  description: PartModifier
  /** Makes your own element the arrow, which the content places on its edge (ember-primitives'). */
  arrow: PartModifier
  /** ember-primitives' name for `anchor`: the element the content is placed against. */
  reference: PartModifier
  /** Sets that element yourself, from a modifier of your own (ember-primitives'). */
  setReference: (element: HTMLElement | SVGElement) => void
  /** Where the content went: its placement, position and middleware data (ember-primitives'). */
  data: AnchorData | undefined
  /** Whether it is open. */
  isOpen: boolean
  /** Whether it is modal. */
  isModal: boolean
  /** Opens it. */
  open: () => void
  /** Opens it if it is closed, and closes it if it is open. */
  toggle: () => void
  /** Opens (`true`) or closes (`false`) it: `(fn p.setOpen false)`. */
  setOpen: (open: boolean) => void
}

export interface PopoverSignature {
  Args: PopoverArgs
  Blocks: { default: [PopoverBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * Rich content in a layer, opened by a button, as Radix's Popover (which shadcn's is built on),
 * and covering ember-primitives' Popover. It renders no box of its own, and yields its parts:
 *
 *   <Popover as |p|>
 *     <p.Trigger>Open</p.Trigger>
 *     <p.Content @side="bottom" @align="start" @sideOffset={{4}}>
 *       <p.Title>Dimensions</p.Title>
 *       …
 *       <p.Close>Done</p.Close>
 *     </p.Content>
 *   </Popover>
 *
 * Its state is its own, or yours with `@open` and `@onOpenChange` (and `@defaultOpen` to start
 * open). While it is open, the content is in the browser's top layer (above everything, with no
 * portal), placed against the trigger and flipped to the other side when there's no room;
 * Escape or a press outside closes it; and focus moves into it, and back to the trigger when it
 * closes. It animates out: it stays until a `data-state="closed"` animation ends.
 *
 * ember-primitives' arguments (`@placement`, `@offsetOptions`, `@flipOptions`,
 * `@shiftOptions`, `@middleware`, `@strategy`) go on the root or the Content, and it yields
 * `reference`, `setReference`, `arrow` and `data` as ember-primitives' does.
 */
export class Popover extends Component<PopoverSignature> {
  openState = controllable(this, 'open', false)
  triggerRef = new ElementRef()
  anchorRef = new ElementRef()
  arrowRef = new ElementRef()
  titleRef = new ElementRef()
  descriptionRef = new ElementRef()
  placed = new PlacedData()

  #interactedOutside = false
  #pointerDownOutside = false
  #rightClickOutside = false

  get id(): string {
    return idFor(this)
  }

  get contentId(): string {
    return idFor(this, 'content')
  }

  get isOpen(): boolean {
    return this.openState.value
  }

  get isModal(): boolean {
    return this.args.modal ?? false
  }

  get state(): 'open' | 'closed' {
    return this.isOpen ? 'open' : 'closed'
  }

  /** Whether focus is kept inside: while a modal popover is open (not while it animates out). */
  get trapsFocus(): boolean {
    return this.isModal && this.isOpen
  }

  /** What the content is placed against: the Anchor, or else the trigger. */
  get reference(): Element | null {
    return this.anchorRef.value ?? this.triggerRef.value
  }

  /** The elements that count as part of the content: the trigger, which toggles it itself. */
  get inside(): Array<Element | null> {
    return [this.triggerRef.value]
  }

  /** What names the content: its Title, or else its trigger. */
  get labelledBy(): string | undefined {
    if (this.titleRef.value) return idFor(this, 'title')
    return this.triggerRef.value?.id || undefined
  }

  get describedBy(): string | undefined {
    return this.descriptionRef.value ? idFor(this, 'description') : undefined
  }

  setOpen = (open: boolean): void => this.openState.set(open)
  show = (): void => this.setOpen(true)
  hide = (): void => this.setOpen(false)
  toggle = (): void => this.openState.set(open => !open)
  dismiss = (_reason: DismissReason): void => this.hide()
  setReference = (element: HTMLElement | SVGElement): void =>
    this.anchorRef.set(element as HTMLElement)

  // ----- What the content does, as Radix's modal and non-modal contents do ------------------

  closeAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
    const interacted = this.#interactedOutside
    const rightClick = this.#rightClickOutside
    this.#interactedOutside = false
    this.#pointerDownOutside = false
    this.#rightClickOutside = false
    if (event.defaultPrevented) return
    event.preventDefault()
    const trigger = this.triggerRef.current?.isConnected ? this.triggerRef.current : null
    // Back to the trigger, unless the user went somewhere else (or, modal, opened a menu).
    if (this.isModal ? !rightClick : !interacted) trigger?.focus()
  }

  pointerDownOutside(
    event: PointerDownOutsideEvent,
    handler?: (event: PointerDownOutsideEvent) => void,
  ): void {
    handler?.(event)
    if (!this.isModal) return
    const original = event.detail.originalEvent
    this.#rightClickOutside = original.button === 2 || (original.button === 0 && original.ctrlKey)
  }

  focusOutside(event: FocusOutsideEvent, handler?: (event: FocusOutsideEvent) => void): void {
    handler?.(event)
    // Focus stays inside a modal popover, so focus outside never closes one.
    if (this.isModal) event.preventDefault()
  }

  interactOutside(
    event: PointerDownOutsideEvent | FocusOutsideEvent,
    handler?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void,
  ): void {
    handler?.(event)
    if (this.isModal) return
    const type = event.detail.originalEvent.type
    if (!event.defaultPrevented) {
      this.#interactedOutside = true
      if (type === 'pointerdown') this.#pointerDownOutside = true
    }
    // A press outside moves focus outside too; the press decided already.
    if (type === 'focusin' && this.#pointerDownOutside) event.preventDefault()
  }

  // ----- The parts ---------------------------------------------------------------------------

  trigger: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      'aria-haspopup': 'dialog',
      'aria-expanded': String(this.isOpen),
      'aria-controls': this.isOpen ? this.contentId : undefined,
      'data-state': this.state,
      'data-test-jn-part': 'trigger',
    },
    on: { click: this.toggle },
    element: element => {
      this.triggerRef.set(element)
      const restoreType = buttonType(element)
      const restoreId = ensureId(element, idFor(this, 'trigger'))
      return () => {
        restoreType()
        restoreId()
        this.triggerRef.release(element)
      }
    },
  }))

  anchor: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'anchor' },
    element: element => {
      this.anchorRef.set(element)
      return () => this.anchorRef.release(element)
    },
  }))

  close: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'close' },
    on: { click: this.hide },
    element: buttonType,
  }))

  title: PartModifier = part<HTMLElement>(() => ({
    attributes: { id: idFor(this, 'title'), 'data-test-jn-part': 'title' },
    element: element => {
      this.titleRef.set(element)
      return () => this.titleRef.release(element)
    },
  }))

  description: PartModifier = part<HTMLElement>(() => ({
    attributes: { id: idFor(this, 'description'), 'data-test-jn-part': 'description' },
    element: element => {
      this.descriptionRef.set(element)
      return () => this.descriptionRef.release(element)
    },
  }))

  arrow: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'arrow' },
    element: element => {
      this.arrowRef.set(element)
      return () => this.arrowRef.release(element)
    },
  }))

  content: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.contentId,
      role: 'dialog',
      'data-state': this.state,
      'data-test-jn-part': 'content',
      'data-test-jn-owner': this.id,
    },
    element: element => exposeProperties(element, 'popover'),
  }))

  <template>
    <div
      id={{this.id}}
      data-test-jn="popover"
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Trigger=(component PopoverTrigger part=this.trigger)
          Anchor=(component PopoverAnchor part=this.anchor)
          Content=(component PopoverContent popover=this)
          Close=(component PopoverClose part=this.close)
          Arrow=(component PopoverArrow popover=this)
          Title=(component PopoverTitle part=this.title)
          Description=(component PopoverDescription part=this.description)
          trigger=this.trigger
          anchor=this.anchor
          close=this.close
          title=this.title
          description=this.description
          arrow=this.arrow
          reference=this.anchor
          setReference=this.setReference
          data=this.placed.data
          isOpen=this.isOpen
          isModal=this.isModal
          open=this.show
          toggle=this.toggle
          setOpen=this.setOpen
        )
      }}
    </div>
  </template>
}

export default Popover
