import Component from '@glimmer/component'
import { array, hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import Modifier from 'ember-modifier'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import type { AnchorOptions } from './anchor/index.ts'
import { controllable, type ControllableArgs } from './controllable-state.ts'
import {
  dismissable,
  type DismissReason,
  type FocusOutsideEvent,
  type PointerDownOutsideEvent,
} from './dismiss.ts'
import { idFor } from './id.ts'
import { topLayer } from './layer.ts'
import { part, type PartModifier } from './part.ts'
import { Presence } from './presence.gts'
import {
  Delay,
  ElementRef,
  PlacedData,
  PopperArrow,
  anchorContent,
  displayContents,
  exposeProperties,
  popperOptions,
  type PopperContentArgs,
} from './-private/popper.gts'

/** What a hover card's Content takes: where it goes (Radix's Popper arguments) and what it does. */
export interface HoverCardContentArgs extends PopperContentArgs {
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Keep it rendered while closed, for animating it yourself. */
  forceMount?: boolean
  /** Escape was pressed. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside it. `preventDefault()` keeps it open. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
  /** Focus moved outside it (it stays open: the trigger's blur closes it). */
  onFocusOutside?: (event: FocusOutsideEvent) => void
  /** Either of the last two, after its own handler. `preventDefault()` keeps it open. */
  onInteractOutside?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void
}

/** Radix's Popper defaults for a hover card: below its trigger, centred, touching it. */
const CONTENT_DEFAULTS: PopperContentArgs = { side: 'bottom', align: 'center', sideOffset: 0 }

function isTouch(event: PointerEvent): boolean {
  return event.pointerType === 'touch'
}

interface TriggerSignature {
  Args: { part: PartModifier; as?: TagName }
  Blocks: { default: [] }
  Element: HTMLAnchorElement
}

/** An `<a>`, or `@as`, that opens the card while the pointer rests on it or it has focus. */
const HoverCardTrigger: TOC<TriggerSignature> = <template>
  <As @as={{@as}} @tag="a" ...attributes {{@part}}>{{yield}}</As>
</template>

interface BehaviourSignature {
  Element: HTMLElement
  Args: { Named: { card: HoverCard } }
}

/**
 * What an open card does, as Radix's content does: a press inside lets the user select its text
 * (and only its text) without the card closing, and the links and buttons inside are out of the
 * tab order, since a hover card is for pointers.
 */
class HoverCardBehaviour extends Modifier<BehaviourSignature> {
  #installed = false

  override modify(content: HTMLElement, _: [], { card }: { card: HoverCard }): void {
    if (this.#installed) return
    this.#installed = true
    const body = document.body.style
    let selecting = false
    const startSelecting = () => {
      if (selecting) return
      selecting = true
      body.setProperty('user-select', 'none')
      body.setProperty('-webkit-user-select', 'none')
      content.style.setProperty('user-select', 'text')
      content.style.setProperty('-webkit-user-select', 'text')
    }
    const stopSelecting = () => {
      if (!selecting) return
      selecting = false
      body.removeProperty('user-select')
      body.removeProperty('-webkit-user-select')
      content.style.removeProperty('user-select')
      content.style.removeProperty('-webkit-user-select')
    }
    const onPointerDown = (event: PointerEvent) => {
      if (event.target instanceof Node && content.contains(event.target)) startSelecting()
      card.hasSelection = false
      card.isPointerDownOnContent = true
    }
    let timer: ReturnType<typeof setTimeout> | undefined
    const onPointerUp = () => {
      stopSelecting()
      card.isPointerDownOnContent = false
      timer = setTimeout(() => {
        if (document.getSelection()?.toString()) card.hasSelection = true
      })
    }
    const untab = () => {
      const walker = document.createTreeWalker(content, NodeFilter.SHOW_ELEMENT)
      for (let node = walker.nextNode(); node; node = walker.nextNode()) {
        if (node instanceof HTMLElement && node.tabIndex >= 0) node.setAttribute('tabindex', '-1')
      }
    }
    const observer = new MutationObserver(untab)
    untab()
    observer.observe(content, { childList: true, subtree: true })
    content.addEventListener('pointerdown', onPointerDown)
    document.addEventListener('pointerup', onPointerUp)

    registerDestructor(this, () => {
      observer.disconnect()
      content.removeEventListener('pointerdown', onPointerDown)
      document.removeEventListener('pointerup', onPointerUp)
      clearTimeout(timer)
      stopSelecting()
      card.hasSelection = false
      card.isPointerDownOnContent = false
    })
  }
}

export interface HoverCardContentSignature {
  Args: HoverCardContentArgs & {
    /** @internal Bound by the hover card. */
    card: HoverCard
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The card itself: in the top layer while it is open (and while it animates out), placed
 * against its trigger (below it, by default) and flipped to stay in view. The pointer can move
 * onto it, and Escape or a press outside closes it.
 */
class HoverCardContent extends Component<HoverCardContentSignature> {
  get anchorOptions(): AnchorOptions {
    const { card } = this.args
    return popperOptions(this.args, {}, CONTENT_DEFAULTS, {
      arrow: card.arrowRef.value,
      setData: card.placed.set,
    })
  }

  onEscapeKeyDown = (event: KeyboardEvent): void => this.args.onEscapeKeyDown?.(event)
  onPointerDownOutside = (event: PointerDownOutsideEvent): void =>
    this.args.onPointerDownOutside?.(event)
  onFocusOutside = (event: FocusOutsideEvent): void => {
    this.args.onFocusOutside?.(event)
    event.preventDefault()
  }
  onInteractOutside = (event: PointerDownOutsideEvent | FocusOutsideEvent): void =>
    this.args.onInteractOutside?.(event)

  <template>
    <Presence @present={{@card.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{presence.ref}}
        {{@card.content}}
        {{topLayer}}
        {{anchorContent @card.reference this.anchorOptions}}
        {{dismissable
          enabled=@card.isOpen
          onDismiss=@card.dismiss
          onEscapeKeyDown=this.onEscapeKeyDown
          onPointerDownOutside=this.onPointerDownOutside
          onFocusOutside=this.onFocusOutside
          onInteractOutside=this.onInteractOutside
          inside=(array @card.triggerRef.value)
        }}
        {{HoverCardBehaviour card=@card}}
      >{{yield}}</As>
    </Presence>
  </template>
}

export interface HoverCardArrowSignature {
  Args: {
    /** @internal Bound by the hover card. */
    card: HoverCard
    /** Its width, in pixels. Default 10. */
    width?: number
    /** Its height, in pixels. Default 5. */
    height?: number
  }
  /** A shape of your own instead of the triangle, inside the `<svg>`. */
  Blocks: { default: [] }
  Element: SVGSVGElement
}

/** Radix's `HoverCard.Arrow`: an `<svg>` triangle on the card's edge, pointing at the trigger. */
const HoverCardArrow: TOC<HoverCardArrowSignature> = <template>
  {{#if (has-block)}}
    <PopperArrow @arrow={{@card.arrowRef}} @width={{@width}} @height={{@height}} ...attributes>
      {{yield}}
    </PopperArrow>
  {{else}}
    <PopperArrow @arrow={{@card.arrowRef}} @width={{@width}} @height={{@height}} ...attributes />
  {{/if}}
</template>

// ----- The hover card ------------------------------------------------------------------------

/** What a `<HoverCard>` takes. */
export type HoverCardArgs = ControllableArgs<'open', boolean> & {
  /** How long the pointer rests on the trigger (or focus stays on it) before it opens, in ms. Default 700. */
  openDelay?: number
  /** How long after the pointer leaves the trigger and the card (or focus leaves) it closes, in ms. Default 300. */
  closeDelay?: number
  /** Its name, for `HoverCardHarness` (`data-test-jn-name`). */
  name?: string
}

/** What a `<HoverCard>` yields. */
export interface HoverCardBlockParams {
  /** An `<a>` that opens the card (`@as` for another tag). */
  Trigger: WithBoundArgs<typeof HoverCardTrigger, 'part'>
  /** The card itself, in the top layer while it is open. */
  Content: WithBoundArgs<typeof HoverCardContent, 'card'>
  /** An arrow on the card's edge, pointing at the trigger. Put it inside the Content. */
  Arrow: WithBoundArgs<typeof HoverCardArrow, 'card'>
  /** Makes your own element or component the trigger: `<Button {{h.trigger}}>`. */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it, at once. */
  setOpen: (open: boolean) => void
}

export interface HoverCardSignature {
  Args: HoverCardArgs
  Blocks: { default: [HoverCardBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A preview of what is behind a link, for sighted users with a pointer, as Radix's HoverCard
 * (which shadcn's is built on). It renders no box of its own, and yields its parts:
 *
 *   <HoverCard @openDelay={{100}} @closeDelay={{200}} as |h|>
 *     <h.Trigger href="/@nextjs">@nextjs</h.Trigger>
 *     <h.Content @side="top" @align="start">…</h.Content>
 *   </HoverCard>
 *
 * It opens once the pointer has rested on the trigger for `@openDelay` (or the trigger has had
 * focus as long), and closes `@closeDelay` after the pointer has left both the trigger and the
 * card (or focus left), unless the user is selecting text in it; Escape and a press outside
 * close it at once. Touch doesn't open it. The state is its own, or yours with `@open` and
 * `@onOpenChange`.
 */
export class HoverCard extends Component<HoverCardSignature> {
  openState = controllable(this, 'open', false)
  triggerRef = new ElementRef()
  arrowRef = new ElementRef()
  placed = new PlacedData()
  openTimer = new Delay(this)
  closeTimer = new Delay(this)
  /** Whether the user selected text in the card, which keeps it open. */
  hasSelection = false
  /** Whether a press inside the card is still down, which keeps it open. */
  isPointerDownOnContent = false

  get id(): string {
    return idFor(this)
  }

  get isOpen(): boolean {
    return this.openState.value
  }

  get state(): 'open' | 'closed' {
    return this.isOpen ? 'open' : 'closed'
  }

  get reference(): Element | null {
    return this.triggerRef.value
  }

  get openDelay(): number {
    return this.args.openDelay ?? 700
  }

  get closeDelay(): number {
    return this.args.closeDelay ?? 300
  }

  handleOpen = (): void => {
    this.closeTimer.cancel()
    this.openTimer.start(this.openDelay, () => this.openState.set(true))
  }

  handleClose = (): void => {
    this.openTimer.cancel()
    if (this.hasSelection || this.isPointerDownOnContent) return
    this.closeTimer.start(this.closeDelay, () => this.openState.set(false))
  }

  setOpen = (open: boolean): void => {
    this.openTimer.cancel()
    this.closeTimer.cancel()
    this.openState.set(open)
  }

  dismiss = (_reason: DismissReason): void => this.setOpen(false)

  trigger: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-state': this.state, 'data-test-jn-part': 'trigger' },
    on: {
      pointerenter: event => !isTouch(event) && this.handleOpen(),
      pointerleave: event => !isTouch(event) && this.handleClose(),
      focus: this.handleOpen,
      blur: this.handleClose,
      // A touch would otherwise follow the link; the card isn't for touch.
      touchstart: event => event.preventDefault(),
    },
    element: element => {
      this.triggerRef.set(element)
      return () => this.triggerRef.release(element)
    },
  }))

  content: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      'data-state': this.state,
      'data-test-jn-part': 'content',
      'data-test-jn-owner': this.id,
    },
    on: {
      pointerenter: event => !isTouch(event) && this.handleOpen(),
      pointerleave: event => !isTouch(event) && this.handleClose(),
    },
    element: element => exposeProperties(element, 'hover-card'),
  }))

  <template>
    <div
      id={{this.id}}
      data-test-jn="hover-card"
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Trigger=(component HoverCardTrigger part=this.trigger)
          Content=(component HoverCardContent card=this)
          Arrow=(component HoverCardArrow card=this)
          trigger=this.trigger
          isOpen=this.isOpen
          setOpen=this.setOpen
        )
      }}
    </div>
  </template>
}

export default HoverCard
