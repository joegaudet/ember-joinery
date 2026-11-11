import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { modifier } from 'ember-modifier'
import type Owner from '@ember/owner'
import { getDirection, type Direction } from '../direction.gts'
import { dismissableBranch } from '../dismiss.ts'
import { topLayer } from '../layer.ts'
import { ToastItem, type ToastHeight, type ToastHost } from './item.gts'
import { styles } from './styles.ts'
import {
  bindToasts,
  toastsFor,
  type SwipeDirection,
  type ToastClassnames,
  type ToastIcons,
  type ToastPosition,
  type ToastStyle,
  type ToastT,
  type Toasts,
} from './state.ts'

// sonner 2.0.7's `Toaster` (MIT, (c) 2023 Emil Kowalski; the notice is in state.ts): the live
// region, one list per position in use, and the stack's expanding on hover, its hotkey and its
// focus handling.

/** How many toasts show at once in a collapsed stack (sonner's `VISIBLE_TOASTS_AMOUNT`). */
const VISIBLE_TOASTS_AMOUNT = 3
/** The space between the stack and the viewport's edges. */
const VIEWPORT_OFFSET = '24px'
/** The same, on a narrow screen (600px or less). */
const MOBILE_VIEWPORT_OFFSET = '16px'
/** A toast's width, in pixels. */
const TOAST_WIDTH = 356
/** The space between toasts in an expanded stack, in pixels. */
const GAP = 14

/** Options every toast in a Toaster takes, as sonner's `toastOptions`. */
export interface ToastOptions {
  className?: string
  closeButton?: boolean
  descriptionClassName?: string
  style?: ToastStyle
  cancelButtonStyle?: ToastStyle
  actionButtonStyle?: ToastStyle
  duration?: number
  unstyled?: boolean
  classNames?: ToastClassnames
  /** The close button's name. Default `Close toast`. */
  closeButtonAriaLabel?: string
}

/** The space between the stack and the viewport's edges: one length, or one per side. */
export type ToastOffset =
  | {
      top?: string | number
      right?: string | number
      bottom?: string | number
      left?: string | number
    }
  | string
  | number

/** A Toaster's colour theme, as sonner's: `system` follows the OS. */
export type ToasterTheme = 'light' | 'dark' | 'system'

export interface ToasterSignature {
  /** Each list (`<ol>`), as sonner's `className` and `style` go on them. */
  Element: HTMLOListElement
  Args: {
    /** Shows only the toasts made with this `toasterId`; without it, those made without one. */
    id?: string
    /** Its name, for `ToasterHarness` (`data-test-jn-name`). */
    name?: string
    /** Dark toasts on a light theme, light on a dark one. */
    invert?: boolean
    /** `light` (the default), `dark`, or `system` to follow the OS. */
    theme?: ToasterTheme
    /** Where toasts show. Default `bottom-right`; a toast's own `position` wins. */
    position?: ToastPosition
    /** The keys that expand the stack and move focus to it. Default `['altKey', 'KeyT']`. */
    hotkey?: string[]
    /** Colours toasts by their type (success green, error red…). */
    richColors?: boolean
    /** Shows the stack expanded, every toast in full, instead of only on hover. */
    expand?: boolean
    /** How long toasts show, in milliseconds. Default 4000. */
    duration?: number
    /** The space between toasts when expanded, in pixels. Default 14. */
    gap?: number
    /** How many toasts show at once. Default 3. */
    visibleToasts?: number
    /** Gives every toast a close button. */
    closeButton?: boolean
    toastOptions?: ToastOptions
    /** Styles for each list, such as the custom properties sonner's CSS reads (`--normal-bg`). */
    style?: ToastStyle
    /** The space between the stack and the viewport's edges. Default `24px`. */
    offset?: ToastOffset
    /** The same on screens 600px wide or less. Default `16px`. */
    mobileOffset?: ToastOffset
    /** The lists' direction. Default the direction where the Toaster is. */
    dir?: Direction | 'auto'
    /** The sides a toast can be swiped off towards. Default the sides of its position. */
    swipeDirections?: SwipeDirection[]
    /** Replaces the icons for each type, and the close button's. */
    icons?: ToastIcons
    /** The region's name, before the hotkey. Default `Notifications`. */
    containerAriaLabel?: string
  }
}

function offsetStyles(offset: ToastOffset | undefined, mobile: ToastOffset | undefined) {
  const result: Record<string, string> = {}
  const px = (value: string | number) => (typeof value === 'number' ? `${value}px` : value)
  for (const [value, prefix, fallback] of [
    [offset, '--offset', VIEWPORT_OFFSET],
    [mobile, '--mobile-offset', MOBILE_VIEWPORT_OFFSET],
  ] as const) {
    for (const side of ['top', 'right', 'bottom', 'left'] as const) {
      if (typeof value === 'number' || typeof value === 'string') {
        result[`${prefix}-${side}`] = px(value)
      } else if (typeof value === 'object' && value !== null) {
        const own = value[side]
        result[`${prefix}-${side}`] = own === undefined ? fallback : px(own)
      } else {
        result[`${prefix}-${side}`] = fallback
      }
    }
  }
  return result
}

const prefersDark = () =>
  typeof matchMedia === 'function' && matchMedia('(prefers-color-scheme: dark)').matches

/**
 * Whether focus on an element shows as the keyboard's (`:focus-visible`): tabbing or the hotkey,
 * not a click or a tap on a toast.
 */
const focusVisible = (element: EventTarget | null): boolean => {
  if (!(element instanceof Element)) return false
  try {
    return element.matches(':focus-visible')
  } catch {
    return true
  }
}

const yOf = (position: string) => position.split('-')[0]
const xOf = (position: string) => position.split('-')[1]

type PopoverElement = HTMLElement & { showPopover(): void; hidePopover(): void }

/**
 * Shows the app's toasts: sonner's `Toaster`, headless. Render it once, in your application
 * template, and make toasts from anywhere with `toast()`:
 *
 *   import { Toaster, toast } from '@ember-joinery/primitives/toast'
 *
 *   <Toaster @position="top-center" @richColors={{true}} />
 *   <button type="button" {{on "click" (fn toast "Saved")}}>Save</button>
 *
 * It renders sonner's markup and data attributes (`data-sonner-toaster`, `data-sonner-toast`,
 * `data-mounted`, `data-expanded`…), which sonner's CSS lays out, stacks and animates;
 * `@ember-joinery/ember`'s `Toaster` ships that CSS, with shadcn's look. Each list is in the
 * browser's top layer, so toasts show above dialogs and popovers, and counts as inside every
 * dismissable layer, so pressing a toast closes none of them.
 *
 * Toasts belong to the app (its owner), not the page, so each test has its own.
 */
export class Toaster extends Component<ToasterSignature> implements ToastHost {
  @tracked heights: readonly ToastHeight[] = []
  @tracked expanded = false
  @tracked interacting = false
  @tracked documentHidden = typeof document !== 'undefined' && document.hidden
  @tracked systemDark = prefersDark()

  #section: HTMLElement | undefined
  /** The newest list, which the hotkey focuses (sonner's `listRef`). */
  #list: HTMLElement | undefined
  #lists = new Set<HTMLElement>()
  #lastFocused: HTMLElement | null = null
  #focusWithin = false
  /** Focus in a list came from the keyboard, which holds the stack open until it leaves. */
  #keyboardFocus = false
  /** A pointer went down on a list since the last key press: the focus that follows is its. */
  #pressed = false
  #hovered = false
  /** Toasts already shown, so a new one can raise its list above layers opened since. */
  #seen = new Set<ToastT['id']>()

  constructor(owner: Owner, args: ToasterSignature['Args']) {
    super(owner, args)
    registerDestructor(this, bindToasts(owner))
    // Rendered on the server (FastBoot), there is no document to listen to.
    if (typeof document === 'undefined') return

    const onKeyDown = (event: KeyboardEvent) => this.#onKeyDown(event)
    const onVisibility = () => (this.documentHidden = document.hidden)
    document.addEventListener('keydown', onKeyDown)
    document.addEventListener('visibilitychange', onVisibility)
    const query =
      typeof matchMedia === 'function' ? matchMedia('(prefers-color-scheme: dark)') : undefined
    const onScheme = (event: MediaQueryListEvent) => (this.systemDark = event.matches)
    query?.addEventListener('change', onScheme)
    registerDestructor(this, () => {
      document.removeEventListener('keydown', onKeyDown)
      document.removeEventListener('visibilitychange', onVisibility)
      query?.removeEventListener('change', onScheme)
    })
  }

  get store(): Toasts {
    return toastsFor(this)
  }

  /** The toasts this Toaster shows: those for its `@id`, or those without a `toasterId`. */
  get toasts(): readonly ToastT[] {
    const { id } = this.args
    const all = this.store.toasts
    return id ? all.filter(toast => toast.toasterId === id) : all.filter(toast => !toast.toasterId)
  }

  get position(): ToastPosition {
    return this.args.position ?? 'bottom-right'
  }

  /** Its own position, then each other position a toast asked for. */
  get positions(): ToastPosition[] {
    const own = this.toasts.map(toast => toast.position).filter(Boolean) as ToastPosition[]
    return [...new Set([this.position, ...own])]
  }

  get theme(): 'light' | 'dark' {
    const theme = this.args.theme ?? 'light'
    if (theme !== 'system') return theme
    return this.systemDark ? 'dark' : 'light'
  }

  get hotkey(): string[] {
    return this.args.hotkey ?? ['altKey', 'KeyT']
  }

  get label(): string {
    const hotkey = this.hotkey.join('+').replace(/Key/g, '').replace(/Digit/g, '')
    return `${this.args.containerAriaLabel ?? 'Notifications'} ${hotkey}`
  }

  get dir(): Direction {
    const dir = this.args.dir
    return dir === 'ltr' || dir === 'rtl' ? dir : getDirection(this.#section ?? null)
  }

  get gap(): number {
    return this.args.gap ?? GAP
  }

  get visibleToasts(): number {
    return this.args.visibleToasts ?? VISIBLE_TOASTS_AMOUNT
  }

  get closeButton(): boolean | undefined {
    return this.args.toastOptions?.closeButton ?? this.args.closeButton
  }

  get duration(): number | undefined {
    return this.args.toastOptions?.duration ?? this.args.duration
  }

  get listStyles(): ToastStyle {
    return {
      '--front-toast-height': `${this.heights[0]?.height || 0}px`,
      '--width': `${TOAST_WIDTH}px`,
      '--gap': `${this.gap}px`,
      ...this.args.style,
      ...offsetStyles(this.args.offset, this.args.mobileOffset),
    }
  }

  /** The toasts in one position's list: those asking for it, and, in the first, the rest. */
  toastsAt = (position: ToastPosition, index: number): ToastT[] =>
    this.toasts.filter(toast => (!toast.position && index === 0) || toast.position === position)

  /** The toasts a toast stacks with: those that asked for the same position, or none. */
  stackOf = (toast: ToastT): number =>
    this.toasts.filter(each => each.position === toast.position).length

  heightsOf = (toast: ToastT): readonly ToastHeight[] =>
    this.heights.filter(height => height.position === toast.position)

  y = yOf
  x = xOf

  /**
   * Updates the toasts' heights, kept newest first, as the toasts are: sonner's order, which
   * is the order its toasts mount in, one at a time. Toasts made together mount together here.
   */
  setHeights(update: (heights: readonly ToastHeight[]) => readonly ToastHeight[]): void {
    if (isDestroying(this) || isDestroyed(this)) return
    const order = new Map(this.store.toasts.map((toast, index) => [toast.id, index]))
    const rank = (height: ToastHeight) => order.get(height.toastId) ?? Infinity
    this.heights = [...update(this.heights)].sort((a, b) => rank(a) - rank(b))
  }

  removeToast(toast: ToastT): void {
    if (isDestroying(this) || isDestroyed(this)) return
    this.store.remove(toast)
  }

  #onKeyDown(event: KeyboardEvent): void {
    this.#pressed = false
    const pressed = this.hotkey.every(
      key => (event as unknown as Record<string, unknown>)[key] || event.code === key,
    )
    if (pressed) {
      this.expanded = true
      this.#list?.focus()
    }
    const active = document.activeElement
    if (
      (event.key === 'Escape' || event.code === 'Escape') &&
      this.#list &&
      (active === this.#list || this.#list.contains(active))
    ) {
      this.expanded = false
    }
  }

  /** Remembers the section, so the lists take the direction where the Toaster is. */
  section = modifier((element: HTMLElement) => {
    this.#section = element
  })

  /**
   * Keeps the stack collapsed once one toast or none is left (sonner's effect on its toasts).
   */
  watch = modifier((_element: HTMLElement, [toasts]: [readonly ToastT[]]) => {
    if (toasts.length <= 1) {
      queueMicrotask(() => {
        if (!isDestroying(this) && !isDestroyed(this)) this.expanded = false
      })
    }
  })

  /** A list: the newest is the one the hotkey focuses (sonner's `listRef`). */
  listRef = modifier((element: HTMLElement) => {
    this.#list = element
    this.#lists.add(element)
    return () => {
      this.#lists.delete(element)
      if (this.#list === element) this.#list = [...this.#lists].at(-1)
      if (this.#lists.size) return
      // The last list is going: give focus back, as sonner does when its list unmounts.
      const last = this.#lastFocused
      this.#lastFocused = null
      this.#focusWithin = false
      this.#keyboardFocus = false
      last?.focus({ preventScroll: true })
    }
  })

  /**
   * When a toast arrives that a list hasn't shown, moves the list to the top of the top layer,
   * above any dialog or popover opened since it was shown, unless focus is in it.
   */
  raise = modifier((element: HTMLElement, [toasts]: [ToastT[]]) => {
    const fresh = toasts.some(toast => !this.#seen.has(toast.id))
    for (const toast of toasts) this.#seen.add(toast.id)
    if (!fresh || element.contains(document.activeElement)) return
    queueMicrotask(() => {
      const popover = element as PopoverElement
      if (!element.isConnected || !element.matches(':popover-open')) return
      try {
        popover.hidePopover()
        popover.showPopover()
      } catch {
        // gone, or shown by someone else
      }
    })
  })

  onFocusIn = (event: FocusEvent): void => {
    const target = event.target
    if (target instanceof HTMLElement && target.dataset['dismissible'] === 'false') return
    if (!this.#focusWithin) {
      this.#focusWithin = true
      this.#lastFocused = event.relatedTarget as HTMLElement | null
    }
    // Joinery: focus from the keyboard (tabbing, the hotkey) expands the stack and pauses the
    // timers, as hovering does, until it leaves the list. sonner's doesn't. A click or a tap on
    // a toast also focuses it, but that focus holds nothing: the pointer leaving collapses the
    // stack and the timers run again, as in sonner.
    this.#keyboardFocus = !this.#pressed && focusVisible(target)
    if (this.#keyboardFocus) this.expanded = true
  }

  onFocusOut = (event: FocusEvent): void => {
    const list = event.currentTarget as HTMLElement
    if (this.#focusWithin && !list.contains(event.relatedTarget as Node | null)) {
      this.#focusWithin = false
      this.#keyboardFocus = false
      if (!this.#hovered && !this.interacting) this.expanded = false
      const last = this.#lastFocused
      this.#lastFocused = null
      last?.focus({ preventScroll: true })
    }
  }

  onMouseEnter = (): void => {
    this.#hovered = true
    this.expanded = true
  }

  onMouseMove = (): void => {
    if (!this.expanded) this.expanded = true
  }

  onMouseLeave = (): void => {
    this.#hovered = false
    // Not while a toast is being pressed or swiped, or the keyboard's focus is in the list.
    if (!this.interacting && !this.#keyboardFocus) this.expanded = false
  }

  onDragEnd = (): void => {
    this.expanded = false
  }

  onPointerDown = (event: PointerEvent): void => {
    this.#pressed = true
    const target = event.target
    if (target instanceof HTMLElement && target.dataset['dismissible'] === 'false') return
    this.interacting = true
  }

  onPointerUp = (): void => {
    this.interacting = false
  }

  <template>
    <section
      aria-label={{this.label}}
      tabindex="-1"
      aria-live="polite"
      aria-relevant="additions text"
      aria-atomic="false"
      data-test-jn="toaster"
      data-test-jn-name={{@name}}
      {{this.section}}
      {{this.watch this.toasts}}
    >
      {{#if this.toasts.length}}
        {{#each this.positions key="@identity" as |position index|}}
          {{#let (this.toastsAt position index) as |toasts|}}
            <ol
              dir={{this.dir}}
              tabindex="-1"
              data-sonner-toaster="true"
              data-sonner-theme={{this.theme}}
              data-y-position={{this.y position}}
              data-x-position={{this.x position}}
              data-test-jn-part="list"
              data-test-jn-value={{position}}
              {{styles this.listStyles}}
              {{topLayer}}
              {{dismissableBranch}}
              {{this.listRef}}
              {{this.raise toasts}}
              {{on "focusin" this.onFocusIn}}
              {{on "focusout" this.onFocusOut}}
              {{on "mouseenter" this.onMouseEnter}}
              {{on "mousemove" this.onMouseMove}}
              {{on "mouseleave" this.onMouseLeave}}
              {{on "dragend" this.onDragEnd}}
              {{on "pointerdown" this.onPointerDown}}
              {{on "pointerup" this.onPointerUp}}
              ...attributes
            >
              {{#each toasts key="id" as |toast toastIndex|}}
                <ToastItem
                  @toast={{toast}}
                  @index={{toastIndex}}
                  @count={{this.stackOf toast}}
                  @heights={{this.heightsOf toast}}
                  @host={{this}}
                  @position={{position}}
                  @expanded={{this.expanded}}
                  @interacting={{this.interacting}}
                  @documentHidden={{this.documentHidden}}
                  @gap={{this.gap}}
                  @visibleToasts={{this.visibleToasts}}
                  @expandByDefault={{if @expand true false}}
                  @invert={{@invert}}
                  @richColors={{@richColors}}
                  @closeButton={{this.closeButton}}
                  @duration={{this.duration}}
                  @className={{@toastOptions.className}}
                  @descriptionClassName={{@toastOptions.descriptionClassName}}
                  @classNames={{@toastOptions.classNames}}
                  @style={{@toastOptions.style}}
                  @unstyled={{@toastOptions.unstyled}}
                  @cancelButtonStyle={{@toastOptions.cancelButtonStyle}}
                  @actionButtonStyle={{@toastOptions.actionButtonStyle}}
                  @closeButtonAriaLabel={{@toastOptions.closeButtonAriaLabel}}
                  @icons={{@icons}}
                  @swipeDirections={{@swipeDirections}}
                />
              {{/each}}
            </ol>
          {{/let}}
        {{/each}}
      {{/if}}
    </section>
  </template>
}
