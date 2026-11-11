import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { array, hash } from '@ember/helper'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { getOwner } from '@ember/owner'
import type Owner from '@ember/owner'
import Modifier, { modifier } from 'ember-modifier'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import type { AnchorOptions } from './anchor/index.ts'
import { ControllableState, type ControllableArgs } from './controllable-state.ts'
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
import { service } from './service.ts'
import {
  Delay,
  ElementRef,
  PlacedData,
  PopperArrow,
  anchorContent,
  buttonType,
  displayContents,
  exposeProperties,
  graceArea,
  isPointInPolygon,
  popperOptions,
  type Point,
  type PopperContentArgs,
} from './-private/popper.gts'

/** Radix's default open delay, in milliseconds. */
const DEFAULT_DELAY_DURATION = 700
/** Radix's default time after one tooltip closes in which the next opens at once. */
const DEFAULT_SKIP_DELAY_DURATION = 300
/** What an opening tooltip tells every other one, so only one is open at a time. */
const TOOLTIP_OPEN = 'tooltip.open'
const PROVIDER = 'data-jn-tooltip-provider'

// ----- Delay groups --------------------------------------------------------------------------

/** What a `TooltipProvider` sets for the tooltips inside it, as Radix's `Tooltip.Provider`. */
export interface TooltipProviderArgs {
  /** How long the pointer rests on a trigger before its tooltip opens, in ms. Default 700. */
  delayDuration?: number
  /**
   * How soon after a tooltip closes the next one opens at once, without its delay, in ms: moving
   * along a toolbar shows each tooltip straight away. Default 300.
   */
  skipDelayDuration?: number
  /** Close as soon as the pointer leaves the trigger, instead of letting it move onto the tooltip. */
  disableHoverableContent?: boolean
}

/**
 * The state the tooltips of one provider share, as Radix's provider keeps it: whether the next
 * one waits for its delay, and whether the pointer is on its way from a trigger to its tooltip.
 */
export class TooltipGroup {
  readonly #settings: () => TooltipProviderArgs
  /** Whether the next tooltip to open waits for its delay; not just after one closed. */
  isOpenDelayed = true
  /** Whether the pointer is crossing from a trigger to its tooltip, or back. */
  isPointerInTransit = false
  #skipTimer: ReturnType<typeof setTimeout> | undefined

  constructor(settings: () => TooltipProviderArgs = () => ({})) {
    this.#settings = settings
  }

  /** The provider's delay, if it sets one. */
  get delayDuration(): number | undefined {
    return this.#settings().delayDuration
  }

  get skipDelayDuration(): number {
    return this.#settings().skipDelayDuration ?? DEFAULT_SKIP_DELAY_DURATION
  }

  get disableHoverableContent(): boolean | undefined {
    return this.#settings().disableHoverableContent
  }

  /** A tooltip in the group opened: the next opens at once. */
  opened(): void {
    clearTimeout(this.#skipTimer)
    this.isOpenDelayed = false
  }

  /** A tooltip in the group closed: the next opens at once, for a moment. */
  closed(): void {
    clearTimeout(this.#skipTimer)
    this.#skipTimer = setTimeout(() => (this.isOpenDelayed = true), this.skipDelayDuration)
  }

  destroy(): void {
    clearTimeout(this.#skipTimer)
  }
}

/** The group of the tooltips that aren't in a provider: one per app instance (and per test). */
class AppTooltipGroup extends TooltipGroup {
  constructor(_owner: Owner) {
    super()
    registerDestructor(this, () => this.destroy())
  }
}

const groups = new WeakMap<Element, TooltipGroup>()

export interface TooltipProviderSignature {
  Args: TooltipProviderArgs & {
    /** The tag to render. Default `div`; use `span` inside phrasing content. */
    as?: TagName
  }
  Blocks: { default: [] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLElement
}

/**
 * Groups the tooltips inside it, as Radix's `Tooltip.Provider`: they share its delays, and once
 * one has opened, the next opens at once (within `@skipDelayDuration`). Tooltips need no
 * provider: those outside one share a group per app.
 *
 *   <TooltipProvider @delayDuration={{300}}>
 *     <Toolbar …/>
 *   </TooltipProvider>
 *
 * It renders an element with `display: contents`, which the tooltips inside find it by.
 */
export class TooltipProvider extends Component<TooltipProviderSignature> {
  group = new TooltipGroup(() => this.args)

  provide = modifier((element: HTMLElement) => {
    groups.set(element, this.group)
    return () => groups.delete(element)
  })

  constructor(owner: Owner, args: TooltipProviderSignature['Args']) {
    super(owner, args)
    registerDestructor(this, () => this.group.destroy())
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      data-jn-tooltip-provider=""
      ...attributes
      {{displayContents}}
      {{this.provide}}
    >{{yield}}</As>
  </template>
}

// ----- The parts -----------------------------------------------------------------------------

/** What a tooltip's Content takes: where it goes (Radix's Popper arguments) and what it does. */
export interface TooltipContentArgs extends PopperContentArgs {
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Keep it rendered while closed, for animating it yourself. */
  forceMount?: boolean
  /** Escape was pressed. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside it. `preventDefault()` keeps it open. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
}

/** Radix's Popper defaults for a tooltip: above its trigger, centred, touching it. */
const CONTENT_DEFAULTS: PopperContentArgs = { side: 'top', align: 'center', sideOffset: 0 }

interface TriggerSignature {
  Args: { part: PartModifier; as?: TagName }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** A `<button type="button">`, or `@as`, that the tooltip describes. */
const TooltipTrigger: TOC<TriggerSignature> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
</template>

/** Whether `destroyable` is being destroyed, or has been. */
function isGoing(destroyable: object | undefined): boolean {
  return destroyable !== undefined && (isDestroying(destroyable) || isDestroyed(destroyable))
}

/** Focus moving elsewhere doesn't close a tooltip: its trigger losing focus does. */
function keepOnFocusOutside(event: FocusOutsideEvent): void {
  event.preventDefault()
}

interface BehaviourSignature {
  Element: HTMLElement
  Args: { Named: { tooltip: Tooltip } }
}

/**
 * What an open tooltip listens for, as Radix's content does: another tooltip opening, a scroll
 * that moves its trigger, and the pointer leaving the trigger or the tooltip for anywhere but
 * the other (its grace area), unless hovering the content is turned off.
 */
class TooltipBehaviour extends Modifier<BehaviourSignature> {
  #installed = false

  override modify(content: HTMLElement, _: [], { tooltip }: { tooltip: Tooltip }): void {
    if (this.#installed) return
    this.#installed = true
    const trigger = tooltip.triggerRef.current
    const close = tooltip.handleClose
    const group = tooltip.group

    const onScroll = (event: Event) => {
      const target = event.target
      if (trigger && target instanceof Node && target.contains(trigger)) close()
    }
    document.addEventListener(TOOLTIP_OPEN, close)
    window.addEventListener('scroll', onScroll, { capture: true })

    let area: Point[] | null = null
    const removeArea = () => {
      area = null
      group.isPointerInTransit = false
      document.removeEventListener('pointermove', onPointerMove)
    }
    const onPointerMove = (event: PointerEvent) => {
      if (!area) return
      const target = event.target
      const entered =
        target instanceof Node && (trigger?.contains(target) || content.contains(target))
      if (entered) removeArea()
      else if (!isPointInPolygon({ x: event.clientX, y: event.clientY }, area)) {
        removeArea()
        close()
      }
    }
    const createArea = (event: PointerEvent, from: Element, to: Element) => {
      area = graceArea(event, from, to)
      group.isPointerInTransit = true
      document.addEventListener('pointermove', onPointerMove)
    }
    const onTriggerLeave = (event: PointerEvent) => trigger && createArea(event, trigger, content)
    const onContentLeave = (event: PointerEvent) => trigger && createArea(event, content, trigger)
    const hoverable = !tooltip.disableHoverableContent
    if (hoverable) {
      trigger?.addEventListener('pointerleave', onTriggerLeave)
      content.addEventListener('pointerleave', onContentLeave)
    }

    registerDestructor(this, () => {
      document.removeEventListener(TOOLTIP_OPEN, close)
      window.removeEventListener('scroll', onScroll, { capture: true })
      trigger?.removeEventListener('pointerleave', onTriggerLeave)
      content.removeEventListener('pointerleave', onContentLeave)
      removeArea()
    })
  }
}

export interface TooltipContentSignature {
  Args: TooltipContentArgs & {
    /** @internal Bound by the tooltip. */
    tooltip: Tooltip
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The tooltip itself, with the `tooltip` role: in the top layer while it is open (and while it
 * animates out), placed against its trigger (above it, by default) and flipped to stay in view.
 * Escape or a press outside closes it.
 */
class TooltipContent extends Component<TooltipContentSignature> {
  get anchorOptions(): AnchorOptions {
    const { tooltip } = this.args
    return popperOptions(this.args, {}, CONTENT_DEFAULTS, {
      arrow: tooltip.arrowRef.value,
      setData: tooltip.placed.set,
    })
  }

  onEscapeKeyDown = (event: KeyboardEvent): void => this.args.onEscapeKeyDown?.(event)
  onPointerDownOutside = (event: PointerDownOutsideEvent): void =>
    this.args.onPointerDownOutside?.(event)

  <template>
    <Presence @present={{@tooltip.isOpen}} @forceMount={{@forceMount}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{presence.ref}}
        {{@tooltip.content}}
        {{topLayer}}
        {{anchorContent @tooltip.reference this.anchorOptions}}
        {{dismissable
          enabled=@tooltip.isOpen
          onDismiss=@tooltip.dismiss
          onEscapeKeyDown=this.onEscapeKeyDown
          onPointerDownOutside=this.onPointerDownOutside
          onFocusOutside=keepOnFocusOutside
          inside=(array @tooltip.triggerRef.value)
        }}
        {{TooltipBehaviour tooltip=@tooltip}}
      >{{yield}}</As>
    </Presence>
  </template>
}

export interface TooltipArrowSignature {
  Args: {
    /** @internal Bound by the tooltip. */
    tooltip: Tooltip
    /** Its width, in pixels. Default 10. */
    width?: number
    /** Its height, in pixels. Default 5. */
    height?: number
  }
  /** A shape of your own instead of the triangle, inside the `<svg>`. */
  Blocks: { default: [] }
  Element: SVGSVGElement
}

/** Radix's `Tooltip.Arrow`: an `<svg>` triangle on the tooltip's edge, pointing at the trigger. */
const TooltipArrow: TOC<TooltipArrowSignature> = <template>
  {{#if (has-block)}}
    <PopperArrow @arrow={{@tooltip.arrowRef}} @width={{@width}} @height={{@height}} ...attributes>
      {{yield}}
    </PopperArrow>
  {{else}}
    <PopperArrow @arrow={{@tooltip.arrowRef}} @width={{@width}} @height={{@height}} ...attributes />
  {{/if}}
</template>

// ----- The tooltip ---------------------------------------------------------------------------

/** What a `<Tooltip>` takes. */
export type TooltipArgs = ControllableArgs<'open', boolean> & {
  /**
   * How long the pointer rests on the trigger before it opens, in ms. It wins over its
   * provider's; without either, `@fallbackDelayDuration`.
   */
  delayDuration?: number
  /** The delay when neither this tooltip nor a provider around it sets one. Default 700, Radix's. */
  fallbackDelayDuration?: number
  /** Close as soon as the pointer leaves the trigger. It wins over its provider's. */
  disableHoverableContent?: boolean
  /** Its name, for `TooltipHarness` (`data-test-jn-name`). */
  name?: string
}

/** How a tooltip is open: after its delay, at once (focus, or just after another), or not. */
export type TooltipState = 'delayed-open' | 'instant-open' | 'closed'

/** What a `<Tooltip>` yields. */
export interface TooltipBlockParams {
  /** A `<button>` that the tooltip describes (`@as` for another tag). */
  Trigger: WithBoundArgs<typeof TooltipTrigger, 'part'>
  /** The tooltip itself, in the top layer while it is open. */
  Content: WithBoundArgs<typeof TooltipContent, 'tooltip'>
  /** An arrow on the tooltip's edge, pointing at the trigger. Put it inside the Content. */
  Arrow: WithBoundArgs<typeof TooltipArrow, 'tooltip'>
  /** Makes your own element or component the trigger: `<Button {{t.trigger}}>`. */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** How it is open: `delayed-open`, `instant-open` or `closed` (its `data-state`). */
  state: TooltipState
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
}

export interface TooltipSignature {
  Args: TooltipArgs
  Blocks: { default: [TooltipBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A popup that describes an element when it has keyboard focus or the pointer rests on it, as
 * Radix's Tooltip (which shadcn's is built on). It renders no box of its own, and yields its
 * parts:
 *
 *   <Tooltip as |t|>
 *     <Button {{t.trigger}}>Hover</Button>
 *     <t.Content @side="top">Add to library<t.Arrow /></t.Content>
 *   </Tooltip>
 *
 * It opens after `@delayDuration` with the pointer on the trigger (at once just after another
 * tooltip closed, as the tooltips of a `TooltipProvider` share their delays), and at once on
 * focus. It closes when the pointer leaves for anywhere but the tooltip, on blur, a press on the
 * trigger, Escape, a press outside, a scroll that moves the trigger, and when another opens.
 * While open, the trigger's `aria-describedby` names the content, whose role is `tooltip`. The
 * state is its own, or yours with `@open` and `@onOpenChange`.
 */
export class Tooltip extends Component<TooltipSignature> {
  openState = new ControllableState<boolean>({
    name: 'open',
    value: () => this.args.open,
    defaultValue: () => this.args.defaultOpen,
    onChange: () => this.onChange,
    fallback: false,
  })
  triggerRef = new ElementRef()
  arrowRef = new ElementRef()
  placed = new PlacedData()
  openDelay = new Delay(this)
  /** Whether it opened after its delay (`delayed-open`) rather than at once. */
  @tracked wasOpenDelayed = false

  #isPointerDown = false
  #hasPointerMoveOpened = false

  get id(): string {
    return idFor(this)
  }

  get contentId(): string {
    return idFor(this, 'content')
  }

  get isOpen(): boolean {
    return this.openState.value
  }

  get state(): TooltipState {
    if (!this.isOpen) return 'closed'
    return this.wasOpenDelayed ? 'delayed-open' : 'instant-open'
  }

  get reference(): Element | null {
    return this.triggerRef.value
  }

  /** The group it is in: its provider's, or the app's. Found from the trigger, when it is used. */
  get group(): TooltipGroup {
    const provider = this.triggerRef.current?.closest(`[${PROVIDER}]`)
    return (provider && groups.get(provider)) || service(this, AppTooltipGroup)
  }

  get delayDuration(): number {
    return (
      this.args.delayDuration ??
      this.group.delayDuration ??
      this.args.fallbackDelayDuration ??
      DEFAULT_DELAY_DURATION
    )
  }

  get disableHoverableContent(): boolean {
    return this.args.disableHoverableContent ?? this.group.disableHoverableContent ?? false
  }

  onChange = (open: boolean): void => {
    if (open) {
      this.group.opened()
      document.dispatchEvent(new CustomEvent(TOOLTIP_OPEN))
    } else {
      this.group.closed()
    }
    this.args.onOpenChange?.(open)
  }

  setOpen = (open: boolean): void => {
    // A focused trigger blurs as the browser removes it, which, as the app is torn down, can be
    // after its provider has gone and while the owner the app's group comes from is going too:
    // a tooltip that is going, or whose app is, changes nothing.
    if (isGoing(this) || isGoing(getOwner(this))) return
    this.openDelay.cancel()
    if (open) this.wasOpenDelayed = false
    this.openState.set(open)
  }

  handleOpen = (): void => this.setOpen(true)
  handleClose = (): void => this.setOpen(false)
  dismiss = (_reason: DismissReason): void => this.handleClose()

  handleDelayedOpen = (): void => {
    this.openDelay.start(this.delayDuration, () => {
      this.wasOpenDelayed = true
      this.openState.set(true)
    })
  }

  onTriggerEnter = (): void => {
    if (this.group.isOpenDelayed) this.handleDelayedOpen()
    else this.handleOpen()
  }

  onTriggerLeave = (): void => {
    if (this.disableHoverableContent) this.handleClose()
    else this.openDelay.cancel()
  }

  #onPointerUp = (): void => {
    this.#isPointerDown = false
  }

  trigger: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      'aria-describedby': this.isOpen ? this.contentId : undefined,
      'data-state': this.state,
      'data-test-jn-part': 'trigger',
    },
    on: {
      pointermove: event => {
        if (event.pointerType === 'touch') return
        if (!this.#hasPointerMoveOpened && !this.group.isPointerInTransit) {
          this.onTriggerEnter()
          this.#hasPointerMoveOpened = true
        }
      },
      pointerleave: () => {
        this.onTriggerLeave()
        this.#hasPointerMoveOpened = false
      },
      pointerdown: () => {
        if (this.isOpen) this.handleClose()
        this.#isPointerDown = true
        document.addEventListener('pointerup', this.#onPointerUp, { once: true })
      },
      focus: () => {
        if (!this.#isPointerDown) this.handleOpen()
      },
      blur: this.handleClose,
      click: this.handleClose,
    },
    element: element => {
      this.triggerRef.set(element)
      const restoreType = buttonType(element)
      return () => {
        restoreType()
        this.triggerRef.release(element)
        document.removeEventListener('pointerup', this.#onPointerUp)
      }
    },
  }))

  content: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.contentId,
      role: 'tooltip',
      'data-state': this.state,
      'data-test-jn-part': 'content',
      'data-test-jn-owner': this.id,
    },
    element: element => exposeProperties(element, 'tooltip'),
  }))

  <template>
    <div
      id={{this.id}}
      data-test-jn="tooltip"
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Trigger=(component TooltipTrigger part=this.trigger)
          Content=(component TooltipContent tooltip=this)
          Arrow=(component TooltipArrow tooltip=this)
          trigger=this.trigger
          isOpen=this.isOpen
          state=this.state
          setOpen=this.setOpen
        )
      }}
    </div>
  </template>
}

export default Tooltip
