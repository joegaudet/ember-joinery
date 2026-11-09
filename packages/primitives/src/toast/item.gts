import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import { modifier } from 'ember-modifier'
import type Owner from '@ember/owner'
import type { ComponentLike } from '@glint/template'
import { CloseIcon, Loader, iconFor } from './icons.gts'
import { styles } from './styles.ts'
import type {
  SwipeDirection,
  ToastAction,
  ToastClassnames,
  ToastContent,
  ToastIcons,
  ToastPosition,
  ToastStyle,
  ToastT,
} from './state.ts'

// sonner 2.0.7's `Toast`: one toast in a Toaster's list, with its timer, its place in the stack
// and its swipe to dismiss.

const waiter = buildWaiter('@ember-joinery/primitives:toast')

/** How long a toast shows, in milliseconds, unless told otherwise (sonner's `TOAST_LIFETIME`). */
export const TOAST_LIFETIME = 4000
/** How far, in pixels, a swipe must go to dismiss a toast (sonner's `SWIPE_THRESHOLD`). */
export const SWIPE_THRESHOLD = 45
/** How long a toast takes to animate out before it is removed (sonner's `TIME_BEFORE_UNMOUNT`). */
export const TIME_BEFORE_UNMOUNT = 200

/** A toast's measured height, which the toasts below it in the stack are placed by. */
export interface ToastHeight {
  toastId: ToastT['id']
  height: number
  position: ToastPosition | undefined
}

/** What a toast tells its Toaster: its height, and when it has animated out. */
export interface ToastHost {
  setHeights(update: (heights: readonly ToastHeight[]) => readonly ToastHeight[]): void
  removeToast(toast: ToastT): void
}

export interface ToastItemSignature {
  Element: HTMLLIElement
  Args: {
    toast: ToastT
    index: number
    /** How many toasts share its position, for its `z-index`. */
    count: number
    heights: readonly ToastHeight[]
    host: ToastHost
    position: ToastPosition
    expanded: boolean
    interacting: boolean
    documentHidden: boolean
    gap: number
    visibleToasts: number
    expandByDefault: boolean
    invert: boolean | undefined
    richColors: boolean | undefined
    closeButton: boolean | undefined
    duration: number | undefined
    className: string | undefined
    descriptionClassName: string | undefined
    classNames: ToastClassnames | undefined
    style: ToastStyle | undefined
    unstyled: boolean | undefined
    cancelButtonStyle: ToastStyle | undefined
    actionButtonStyle: ToastStyle | undefined
    closeButtonAriaLabel: string | undefined
    icons: ToastIcons | undefined
    swipeDirections: SwipeDirection[] | undefined
  }
}

type SwipeOut = 'left' | 'right' | 'up' | 'down'

function cn(...classes: (string | undefined | false)[]): string | undefined {
  const joined = classes.filter(Boolean).join(' ')
  return joined || undefined
}

const bool = (value: boolean): 'true' | 'false' => (value ? 'true' : 'false')

/** An optional boolean as React renders it on a `data-` attribute: left off when unset. */
const optional = (value: boolean | undefined): 'true' | 'false' | undefined =>
  value === undefined ? undefined : bool(value)

function isAction(action: ToastAction | ComponentLike | undefined): action is ToastAction {
  return typeof action === 'object' && action !== null && 'label' in action
}

function defaultSwipeDirections(position: ToastPosition): SwipeDirection[] {
  const [y, x] = position.split('-') as [SwipeDirection, SwipeDirection | 'center']
  const directions: SwipeDirection[] = []
  if (y) directions.push(y)
  if (x && x !== ('center' as string)) directions.push(x as SwipeDirection)
  return directions
}

/** Runs `callback` once the render is over: a render can't change state it has read. */
function afterRender(owner: object, callback: () => void): void {
  const token = waiter.beginAsync()
  queueMicrotask(() => {
    try {
      if (!isDestroying(owner) && !isDestroyed(owner)) callback()
    } finally {
      waiter.endAsync(token)
    }
  })
}

/**
 * A toast's height with its content laid out in full, as sonner measures it (with `height:
 * auto`): its layout height, which a collapsed stack's scaling doesn't change, so toasts made
 * together measure as each would alone in front.
 */
function naturalHeight(element: HTMLElement): number {
  const original = element.style.height
  element.style.height = 'auto'
  const height = Number.parseFloat(getComputedStyle(element).height) || 0
  element.style.height = original
  return height
}

const notLoading = (type: string | undefined): boolean => type !== 'loading'

const text = (content: ToastContent | undefined): string | undefined =>
  typeof content === 'string' ? content : undefined

const component = (content: ToastContent | undefined): ComponentLike | undefined =>
  content === undefined || typeof content === 'string' ? undefined : content

export class ToastItem extends Component<ToastItemSignature> {
  @tracked mounted = false
  @tracked removed = false
  @tracked swiping = false
  @tracked swipeOut = false
  @tracked isSwiped = false
  @tracked swipeOutDirection: SwipeOut | null = null
  @tracked offsetBeforeRemove = 0
  @tracked initialHeight = 0

  #element: HTMLLIElement | undefined
  #swipeDirection: 'x' | 'y' | null = null
  #remainingTime: number
  #duration: number
  #closeTimerStart = 0
  #lastCloseTimerStart = 0
  #dragStart: number | null = null
  #pointerStart: { x: number; y: number } | null = null
  #deleted = false

  constructor(owner: Owner, args: ToastItemSignature['Args']) {
    super(owner, args)
    this.#remainingTime = this.#duration = this.duration
    registerDestructor(this, () => {
      const id = this.args.toast.id
      const host = this.args.host
      queueMicrotask(() => host.setHeights(heights => heights.filter(h => h.toastId !== id)))
    })
  }

  get toast(): ToastT {
    return this.args.toast
  }

  get type() {
    return this.toast.type
  }

  get isFront(): boolean {
    return this.args.index === 0
  }

  get isVisible(): boolean {
    return this.args.index + 1 <= this.args.visibleToasts
  }

  get dismissible(): boolean {
    return this.toast.dismissible !== false
  }

  get isPromise(): boolean {
    return Boolean(this.toast.promise)
  }

  get disabled(): boolean {
    return this.type === 'loading'
  }

  get duration(): number {
    return this.toast.duration || this.args.duration || TOAST_LIFETIME
  }

  get y(): string {
    return this.args.position.split('-')[0]!
  }

  get x(): string {
    return this.args.position.split('-')[1]!
  }

  /** Where its height is in the stack (sonner's `heightIndex`, `-1` before it is measured). */
  get heightIndex(): number {
    return this.args.heights.findIndex(height => height.toastId === this.toast.id) || 0
  }

  get toastsHeightBefore(): number {
    return this.args.heights.reduce(
      (sum, height, index) => (index >= this.heightIndex ? sum : sum + height.height),
      0,
    )
  }

  /** How far it sits from the front of an expanded stack, in pixels. */
  get offset(): number {
    return this.heightIndex * this.args.gap + this.toastsHeightBefore
  }

  get classes(): string | undefined {
    const { classNames } = this.args
    const own = this.toast.classNames
    const type = this.type as keyof ToastClassnames | undefined
    return cn(
      this.args.className,
      this.toast.className,
      classNames?.toast,
      own?.toast,
      classNames?.default,
      type && classNames?.[type],
      type && own?.[type],
    )
  }

  get richColors(): 'true' | 'false' | undefined {
    return optional(this.toast.richColors ?? this.args.richColors)
  }

  get styled(): 'true' | 'false' {
    return bool(!(this.toast.component || this.toast.unstyled || this.args.unstyled))
  }

  get invert(): 'true' | 'false' | undefined {
    return optional(this.toast.invert || this.args.invert || undefined)
  }

  get expanded(): 'true' | 'false' {
    return bool(this.args.expanded || (this.args.expandByDefault && this.mounted))
  }

  get vars(): ToastStyle {
    const { index, count } = this.args
    return {
      '--index': String(index),
      '--toasts-before': String(index),
      '--z-index': String(count - index),
      '--offset': `${this.removed ? this.offsetBeforeRemove : this.offset}px`,
      '--initial-height': this.args.expandByDefault ? 'auto' : `${this.initialHeight}px`,
      ...this.args.style,
      ...this.toast.style,
    }
  }

  get showCloseButton(): boolean {
    const closeButton = this.toast.closeButton ?? this.args.closeButton
    return Boolean(closeButton && !this.toast.component && this.type !== 'loading')
  }

  get CloseIcon(): ComponentLike {
    return this.args.icons?.close ?? CloseIcon
  }

  get showIcon(): boolean {
    const { toast, type } = this
    const icons = this.args.icons as Record<string, ComponentLike | null | undefined> | undefined
    return Boolean(
      (type || toast.icon || toast.promise) &&
      toast.icon !== null &&
      (icons?.[type ?? ''] !== null || toast.icon),
    )
  }

  /** Whether the loading spinner shows (and, once a promise settles, fades out). */
  get showLoader(): boolean {
    return Boolean(this.toast.promise || (this.type === 'loading' && !this.toast.icon))
  }

  get loaderVisible(): boolean {
    return this.type === 'loading'
  }

  get loaderClass(): string | undefined {
    return cn(this.args.classNames?.loader, this.toast.classNames?.loader)
  }

  get LoadingIcon(): ComponentLike | null | undefined {
    return this.args.icons?.loading
  }

  get Icon(): ComponentLike | null {
    const icons = this.args.icons as Record<string, ComponentLike | null | undefined> | undefined
    return this.toast.icon || icons?.[this.type ?? ''] || iconFor(this.type)
  }

  get titleText(): string | undefined {
    return text(this.toast.title)
  }

  get Title(): ComponentLike | undefined {
    return component(this.toast.title)
  }

  get descriptionText(): string | undefined {
    return text(this.toast.description)
  }

  get Description(): ComponentLike | undefined {
    return component(this.toast.description)
  }

  get descriptionClass(): string | undefined {
    return cn(
      this.args.descriptionClassName,
      this.toast.descriptionClassName,
      this.args.classNames?.description,
      this.toast.classNames?.description,
    )
  }

  get cancel(): ToastAction | undefined {
    return isAction(this.toast.cancel) ? this.toast.cancel : undefined
  }

  get Cancel(): ComponentLike | undefined {
    const cancel = this.toast.cancel
    return cancel && !isAction(cancel) ? cancel : undefined
  }

  get action(): ToastAction | undefined {
    return isAction(this.toast.action) ? this.toast.action : undefined
  }

  get Action(): ComponentLike | undefined {
    const action = this.toast.action
    return action && !isAction(action) ? action : undefined
  }

  get cancelStyle(): ToastStyle | undefined {
    return this.toast.cancelButtonStyle || this.args.cancelButtonStyle
  }

  get actionStyle(): ToastStyle | undefined {
    return this.toast.actionButtonStyle || this.args.actionButtonStyle
  }

  part = (name: keyof ToastClassnames, extra?: string): string | undefined =>
    cn(this.args.classNames?.[name], this.toast.classNames?.[name], extra)

  /** Closes it: it animates out, and its Toaster removes it. */
  deleteToast = (): void => {
    if (this.removed) return
    this.removed = true
    this.offsetBeforeRemove = this.offset
    const id = this.toast.id
    this.args.host.setHeights(heights => heights.filter(height => height.toastId !== id))
    const toast = this.toast
    const host = this.args.host
    const token = waiter.beginAsync()
    setTimeout(() => {
      try {
        host.removeToast(toast)
      } finally {
        waiter.endAsync(token)
      }
    }, TIME_BEFORE_UNMOUNT)
  }

  #dismiss(): void {
    this.deleteToast()
    this.toast.onDismiss?.(this.toast)
  }

  /** Measures it when it is first shown, and starts its entrance. */
  setup = modifier((element: HTMLLIElement) => {
    this.#element = element
    // Once the render is over: the list's modifiers, which set its width, run after its toasts'.
    afterRender(this, () => {
      const height = naturalHeight(element)
      this.initialHeight = height
      const { id, position } = this.toast
      this.args.host.setHeights(heights => [{ toastId: id, height, position }, ...heights])
      // Measuring it laid it out unmounted (below and transparent), so turning `data-mounted`
      // on now is a transition, as sonner's effect after the first paint is.
      this.mounted = true
    })
  })

  /** Measures it again whenever what it shows changes (sonner's layout effect). */
  remeasure = modifier((element: HTMLLIElement, [mounted]: [boolean, ...unknown[]]) => {
    if (!mounted) return
    afterRender(this, () => {
      const height = naturalHeight(element)
      this.initialHeight = height
      const { id, position } = this.toast
      this.args.host.setHeights(heights =>
        heights.some(each => each.toastId === id)
          ? heights.map(each => (each.toastId === id ? { ...each, height } : each))
          : [{ toastId: id, height, position }, ...heights],
      )
    })
  })

  /** Starts its exit when `toast.dismiss()` marks it deleted. */
  watchDelete = modifier((_element: HTMLLIElement, [deleted]: [boolean | undefined]) => {
    if (!deleted || this.#deleted) return
    this.#deleted = true
    afterRender(this, () => this.#dismiss())
  })

  /**
   * Runs its timer while the stack is collapsed, the pointer isn't on it and the page is
   * showing, and pauses it otherwise (sonner's timer effect). A loading toast, a promise that
   * hasn't settled and `duration: Infinity` have none.
   */
  timer = modifier(
    (
      _element: HTMLLIElement,
      [paused, toast, duration]: [boolean, ToastT, number],
    ): (() => void) | undefined => {
      if (duration !== this.#duration) this.#remainingTime = this.#duration = duration
      if (
        (toast.promise && toast.type === 'loading') ||
        toast.duration === Infinity ||
        toast.type === 'loading'
      ) {
        return
      }
      if (paused) {
        if (this.#lastCloseTimerStart < this.#closeTimerStart) {
          this.#remainingTime -= Date.now() - this.#closeTimerStart
        }
        this.#lastCloseTimerStart = Date.now()
        return
      }
      if (this.#remainingTime === Infinity) return
      this.#closeTimerStart = Date.now()
      const timeout = setTimeout(() => {
        toast.onAutoClose?.(toast)
        this.deleteToast()
      }, this.#remainingTime)
      return () => clearTimeout(timeout)
    },
  )

  get paused(): boolean {
    return this.args.expanded || this.args.interacting || this.args.documentHidden
  }

  onPointerDown = (event: PointerEvent): void => {
    if (event.button === 2) return
    if (this.disabled || !this.dismissible) return
    this.#dragStart = Date.now()
    this.offsetBeforeRemove = this.offset
    const target = event.target as Element
    try {
      // Keeps the pointer's events coming here even once it leaves the toast, as it swipes.
      target.setPointerCapture(event.pointerId)
    } catch {
      // not an active pointer (a synthetic event)
    }
    if (target.tagName === 'BUTTON') return
    this.swiping = true
    this.#pointerStart = { x: event.clientX, y: event.clientY }
  }

  onPointerUp = (): void => {
    if (this.swipeOut || !this.dismissible) return
    this.#pointerStart = null
    const style = this.#element?.style
    const amountX = Number(style?.getPropertyValue('--swipe-amount-x').replace('px', '') || 0)
    const amountY = Number(style?.getPropertyValue('--swipe-amount-y').replace('px', '') || 0)
    const timeTaken = this.#dragStart === null ? NaN : Date.now() - this.#dragStart
    const amount = this.#swipeDirection === 'x' ? amountX : amountY
    const velocity = Math.abs(amount) / timeTaken

    if (Math.abs(amount) >= SWIPE_THRESHOLD || velocity > 0.11) {
      this.offsetBeforeRemove = this.offset
      this.toast.onDismiss?.(this.toast)
      if (this.#swipeDirection === 'x') this.swipeOutDirection = amountX > 0 ? 'right' : 'left'
      else this.swipeOutDirection = amountY > 0 ? 'down' : 'up'
      this.deleteToast()
      this.swipeOut = true
      return
    }
    style?.setProperty('--swipe-amount-x', '0px')
    style?.setProperty('--swipe-amount-y', '0px')
    this.isSwiped = false
    this.swiping = false
    this.#swipeDirection = null
  }

  onPointerMove = (event: PointerEvent): void => {
    const start = this.#pointerStart
    if (!start || !this.dismissible) return
    if ((window.getSelection()?.toString().length ?? 0) > 0) return // selecting text
    const yDelta = event.clientY - start.y
    const xDelta = event.clientX - start.x
    const directions = this.args.swipeDirections ?? defaultSwipeDirections(this.args.position)

    if (!this.#swipeDirection && (Math.abs(xDelta) > 1 || Math.abs(yDelta) > 1)) {
      this.#swipeDirection = Math.abs(xDelta) > Math.abs(yDelta) ? 'x' : 'y'
    }
    const amount = { x: 0, y: 0 }
    // Against an allowed direction, the toast follows the pointer less and less.
    const dampened = (delta: number) => {
      const value = delta * (1 / (1.5 + Math.abs(delta) / 20))
      return Math.abs(value) < Math.abs(delta) ? value : delta
    }
    if (this.#swipeDirection === 'y') {
      if (directions.includes('top') || directions.includes('bottom')) {
        amount.y =
          (directions.includes('top') && yDelta < 0) ||
          (directions.includes('bottom') && yDelta > 0)
            ? yDelta
            : dampened(yDelta)
      }
    } else if (this.#swipeDirection === 'x') {
      if (directions.includes('left') || directions.includes('right')) {
        amount.x =
          (directions.includes('left') && xDelta < 0) ||
          (directions.includes('right') && xDelta > 0)
            ? xDelta
            : dampened(xDelta)
      }
    }
    if (Math.abs(amount.x) > 0 || Math.abs(amount.y) > 0) this.isSwiped = true
    this.#element?.style.setProperty('--swipe-amount-x', `${amount.x}px`)
    this.#element?.style.setProperty('--swipe-amount-y', `${amount.y}px`)
  }

  onDragEnd = (): void => {
    this.swiping = false
    this.#swipeDirection = null
    this.#pointerStart = null
  }

  onClose = (): void => {
    if (this.disabled || !this.dismissible) return
    this.#dismiss()
  }

  onCancel = (cancel: ToastAction, event: MouseEvent): void => {
    if (!this.dismissible) return
    cancel.onClick?.(event)
    this.deleteToast()
  }

  onAction = (action: ToastAction, event: MouseEvent): void => {
    action.onClick?.(event)
    if (event.defaultPrevented) return
    this.deleteToast()
  }

  <template>
    <li
      tabindex="0"
      class={{this.classes}}
      data-sonner-toast=""
      data-rich-colors={{this.richColors}}
      data-styled={{this.styled}}
      data-mounted={{bool this.mounted}}
      data-promise={{bool this.isPromise}}
      data-swiped={{bool this.isSwiped}}
      data-removed={{bool this.removed}}
      data-visible={{bool this.isVisible}}
      data-y-position={{this.y}}
      data-x-position={{this.x}}
      data-index={{@index}}
      data-front={{bool this.isFront}}
      data-swiping={{bool this.swiping}}
      data-dismissible={{bool this.dismissible}}
      data-type={{this.type}}
      data-invert={{this.invert}}
      data-swipe-out={{bool this.swipeOut}}
      data-swipe-direction={{this.swipeOutDirection}}
      data-expanded={{this.expanded}}
      data-testid={{this.toast.testId}}
      data-test-jn="toast"
      data-test-jn-name="{{this.toast.id}}"
      {{styles this.vars}}
      {{this.setup}}
      {{this.remeasure
        this.mounted
        this.toast.title
        this.toast.description
        this.toast.component
        this.toast.action
        this.toast.cancel
      }}
      {{this.watchDelete this.toast.delete}}
      {{this.timer this.paused this.toast this.duration}}
      {{on "pointerdown" this.onPointerDown}}
      {{on "pointerup" this.onPointerUp}}
      {{on "pointermove" this.onPointerMove}}
      {{on "dragend" this.onDragEnd}}
    >
      {{#if this.showCloseButton}}
        <button
          type="button"
          aria-label={{if @closeButtonAriaLabel @closeButtonAriaLabel "Close toast"}}
          data-disabled={{bool this.disabled}}
          data-close-button="true"
          class={{this.part "closeButton"}}
          data-test-jn-part="close"
          {{on "click" this.onClose}}
        ><this.CloseIcon /></button>
      {{/if}}
      {{#if this.showIcon}}
        <div data-icon="" class={{this.part "icon"}} data-test-jn-part="icon">
          {{#if this.showLoader}}
            {{#if this.toast.icon}}
              <this.toast.icon />
            {{else if this.LoadingIcon}}
              <div
                class={{this.part "loader" "sonner-loader"}}
                data-visible={{bool this.loaderVisible}}
              ><this.LoadingIcon /></div>
            {{else}}
              <Loader @class={{this.loaderClass}} @visible={{this.loaderVisible}} />
            {{/if}}
          {{/if}}
          {{#if (notLoading this.type)}}
            {{#if this.Icon}}<this.Icon />{{/if}}
          {{/if}}
        </div>
      {{/if}}
      <div data-content="" class={{this.part "content"}}>
        <div data-title="" class={{this.part "title"}} data-test-jn-part="title">
          {{#if this.toast.component}}
            <this.toast.component @id={{this.toast.id}} @dismiss={{this.deleteToast}} />
          {{else if this.Title}}
            <this.Title />
          {{else}}
            {{this.titleText}}
          {{/if}}
        </div>
        {{#if this.toast.description}}
          <div data-description="" class={{this.descriptionClass}} data-test-jn-part="description">
            {{#if this.Description}}<this.Description />{{else}}{{this.descriptionText}}{{/if}}
          </div>
        {{/if}}
      </div>
      {{#if this.Cancel}}
        <this.Cancel />
      {{else if this.cancel}}
        <button
          type="button"
          data-button="true"
          data-cancel="true"
          class={{this.part "cancelButton"}}
          data-test-jn-part="cancel"
          {{styles this.cancelStyle}}
          {{on "click" (fn this.onCancel this.cancel)}}
        >{{this.cancel.label}}</button>
      {{/if}}
      {{#if this.Action}}
        <this.Action />
      {{else if this.action}}
        <button
          type="button"
          data-button="true"
          data-action="true"
          class={{this.part "actionButton"}}
          data-test-jn-part="action"
          {{styles this.actionStyle}}
          {{on "click" (fn this.onAction this.action)}}
        >{{this.action.label}}</button>
      {{/if}}
    </li>
  </template>
}
