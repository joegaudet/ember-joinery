import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import Modifier, { modifier } from 'ember-modifier'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import type { AnchorOptions } from './anchor/index.ts'
import { controllable, type ControllableArgs } from './controllable-state.ts'
import { getDirection, type Direction } from './direction.gts'
import { dismissable, type PointerDownOutsideEvent } from './dismiss.ts'
import { addFocusGuards, createFocusScope, type FocusScopeHandle } from './focus-scope.gts'
import { focusFirst } from './focus.ts'
import { inertOthers, type Undo } from './hide-others.ts'
import { idFor } from './id.ts'
import { topLayer } from './layer.ts'
import { part, type PartModifier } from './part.ts'
import { scrollLock } from './scroll-lock.ts'
import { Typeahead, getNextMatch, isTypeaheadKey } from './typeahead.ts'
import {
  ElementRef,
  PopperArrow,
  anchorContent,
  buttonType,
  displayContents,
  ensureId,
  exposeProperties,
  popperOptions,
  type PopperContentArgs,
} from './-private/popper.gts'

// Radix's Select (@radix-ui/react-select 2.2.6, the version radix-ui 1.4.3 pins), which
// shadcn's Select is built on: a button that opens a listbox of options, with the selected
// option over the button (`item-aligned`) or below it (`popper`), typeahead on both, and a
// hidden native `<select>` in a form.

const OPEN_KEYS = [' ', 'Enter', 'ArrowUp', 'ArrowDown']
const SELECTION_KEYS = [' ', 'Enter']
/** How far the item-aligned content stays from the viewport's edges, as Radix's. */
const CONTENT_MARGIN = 10

/** Where the content goes: over its trigger, the selected option on the value (Radix's default), or below it. */
export type SelectPosition = 'item-aligned' | 'popper'

/** Whether the value shows the placeholder: none chosen, as Radix's `shouldShowPlaceholder`. */
function showsPlaceholder(value: string | undefined): boolean {
  return value === '' || value === undefined
}

function clamp(value: number, [min, max]: [number, number]): number {
  return Math.min(max, Math.max(min, value))
}

function byDocumentOrder(a: { element: Element }, b: { element: Element }): number {
  if (a.element === b.element) return 0
  return a.element.compareDocumentPosition(b.element) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
}

function setStyles(element: HTMLElement, styles: Record<string, string>): () => void {
  const previous = Object.keys(styles).map(
    property =>
      [
        property,
        element.style.getPropertyValue(property),
        element.style.getPropertyPriority(property),
      ] as const,
  )
  for (const [property, value] of Object.entries(styles)) element.style.setProperty(property, value)
  return () => {
    for (const [property, value, priority] of previous) {
      if (value) element.style.setProperty(property, value, priority)
      else element.style.removeProperty(property)
    }
  }
}

// ----- Arguments -----------------------------------------------------------------------------

/** What a `<Select>` takes: Radix's Select props, by Joinery's names. */
export type SelectArgs = ControllableArgs<'open', boolean> &
  ControllableArgs<'value', string> & {
    /** The text direction, for the item-aligned position and the arrow keys. Default: the page's. */
    dir?: Direction
    /** The form field's name (Radix's `name`): the hidden native `<select>` takes it. */
    formName?: string
    /** The hidden `<select>`'s `autocomplete`, for the browser's autofill. */
    autoComplete?: string
    /** Disables the trigger, so it can't be opened. */
    disabled?: boolean
    /** Marks it required: `aria-required` on the trigger and `required` on the hidden `<select>`. */
    required?: boolean
    /** The id of the form the hidden `<select>` belongs to, outside it. */
    form?: string
    /** Its name, for `SelectHarness` (`data-test-jn-name`). */
    name?: string
  }

/** What a select's Content takes: where it goes, and what Escape and a press outside do. */
export interface SelectContentArgs extends PopperContentArgs {
  /** `item-aligned` (the default): the selected option sits over the trigger. `popper`: below it. */
  position?: SelectPosition
  /** The tag to render. Default `div`. */
  as?: TagName
  /** Called when it has closed, before focus goes back to the trigger. `preventDefault()` to send focus elsewhere. */
  onCloseAutoFocus?: (event: Event) => void
  /** Escape was pressed. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside it. `preventDefault()` keeps it open. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
}

/** Radix's defaults for the `popper` position: below, at the start, 10px from the viewport's edges. */
const POPPER_DEFAULTS: PopperContentArgs = {
  side: 'bottom',
  align: 'start',
  sideOffset: 0,
  collisionPadding: CONTENT_MARGIN,
}

// ----- The open content's state ---------------------------------------------------------------

/**
 * What the open content knows, for the parts inside it: its element, its viewport, whether it
 * has been placed, and whether its viewport can scroll either way (the scroll buttons show then).
 */
export class SelectContentState {
  readonly select: Select
  readonly position: SelectPosition
  content: HTMLElement | null = null
  wrapper: HTMLElement | null = null
  viewport = new ElementRef()
  @tracked isPositioned = false
  @tracked canScrollUp = false
  @tracked canScrollDown = false
  /** Whether a viewport scroll should grow the item-aligned content (on once it is placed). */
  expandOnScroll = false
  /** Whether a scroll button appearing should place the content again (once). */
  repositionOnScrollButton = true
  /** The function that places the item-aligned content, once it is shown. */
  reposition: (() => void) | undefined
  /** The content's typeahead, which focuses the next option starting with what was typed. */
  readonly typeahead = new Typeahead()

  constructor(select: Select, position: SelectPosition) {
    this.select = select
    this.position = position
  }

  /** The option to show and focus first: the selected one, or else the first that isn't disabled. */
  get selectedItem(): SelectItem | undefined {
    const items = this.select.items
    const value = this.select.value
    return (
      items.find(item => !showsPlaceholder(value) && item.value === value) ??
      items.find(item => !item.isDisabled)
    )
  }

  /** Focuses the first of `candidates` that takes focus, scrolling it into view, as Radix's. */
  focusFirst(candidates: Array<HTMLElement | null | undefined>): void {
    const items = this.select.items.map(item => item.element)
    const first = items[0]
    const last = items.at(-1)
    const viewport = this.viewport.current
    const previous = document.activeElement
    for (const candidate of candidates) {
      if (!candidate) continue
      if (candidate === previous) return
      candidate.scrollIntoView({ block: 'nearest' })
      // The viewport may have padding, so scroll to its edges for the first and last items.
      if (candidate === first && viewport) viewport.scrollTop = 0
      if (candidate === last && viewport) viewport.scrollTop = viewport.scrollHeight
      if (focusFirst([candidate], { preventScroll: true })) return
    }
  }

  focusSelectedItem = (): void => {
    this.focusFirst([this.selectedItem?.element, this.content])
  }

  /** A pointer left an item (or moved onto a disabled one): focus goes back to the content. */
  itemLeft = (): void => {
    this.content?.focus({ preventScroll: true })
  }

  /** Whether the viewport can scroll up or down now. */
  measureScroll = (): void => {
    const viewport = this.viewport.current
    if (!viewport || !this.isPositioned) return
    const up = viewport.scrollTop > 0
    // Rounded up, because a zoomed page doesn't always report whole pixels.
    const down = Math.ceil(viewport.scrollTop) < viewport.scrollHeight - viewport.clientHeight
    if (up !== this.canScrollUp) this.canScrollUp = up
    if (down !== this.canScrollDown) this.canScrollDown = down
  }

  /** A scroll button appeared: it pushes the viewport, so place the content again, once. */
  scrollButtonShown = (): void => {
    if (!this.repositionOnScrollButton || !this.reposition) return
    this.repositionOnScrollButton = false
    this.reposition()
    this.focusSelectedItem()
  }

  placed = (): void => {
    this.isPositioned = true
    this.focusSelectedItem()
    this.measureScroll()
  }
}

// ----- Modifiers -----------------------------------------------------------------------------

interface ContentBehaviourSignature {
  Element: HTMLElement
  Args: { Named: { content: SelectContent } }
}

/**
 * Everything the open content does that isn't anchoring or dismissal, as Radix's
 * `SelectContentImpl`: its inline layout, keyboard (arrows, Home, End, typeahead, no Tab), no
 * context menu, focus trapped inside with focus guards and the rest of the page inert (Radix
 * hides it from assistive technology; inert does that and keeps focus off it, as
 * `CONTRIBUTING.md` asks of a modal part), the pointer that opened it not selecting on release,
 * and closing when the window loses focus or resizes.
 */
class ContentBehaviour extends Modifier<ContentBehaviourSignature> {
  #installed = false

  override modify(element: HTMLElement, _: [], { content }: { content: SelectContent }): void {
    if (this.#installed) return
    this.#installed = true
    const select = content.select
    const state = content.state
    state.content = element

    const restoreStyles = setStyles(element, {
      display: 'flex',
      'flex-direction': 'column',
      outline: 'none',
      'box-sizing': 'border-box',
      ...(state.position === 'item-aligned' ? { 'max-height': '100%' } : {}),
    })
    const restoreProperties =
      state.position === 'popper' ? exposeProperties(element, 'select') : () => {}
    // Focusable itself, as Radix's FocusScope makes it, for when no option has focus.
    const ownTabindex = element.hasAttribute('tabindex')
    if (!ownTabindex) element.setAttribute('tabindex', '-1')
    // Named by its trigger, unless the caller named it.
    const named = element.hasAttribute('aria-label') || element.hasAttribute('aria-labelledby')
    const triggerId = select.triggerRef.current?.id
    if (!named && triggerId) element.setAttribute('aria-labelledby', triggerId)

    const onKeyDown = (event: KeyboardEvent) => content.keyDown(event)
    const onContextMenu = (event: Event) => event.preventDefault()
    element.addEventListener('keydown', onKeyDown)
    element.addEventListener('contextmenu', onContextMenu)

    // The press that opened it from the trigger: its release doesn't select unless the pointer
    // moved, and a release outside closes it.
    let moved = { x: 0, y: 0 }
    const start = select.triggerPointerDownPosition
    const onPointerMove = (event: PointerEvent) => {
      moved = {
        x: Math.abs(Math.round(event.pageX) - (start?.x ?? 0)),
        y: Math.abs(Math.round(event.pageY) - (start?.y ?? 0)),
      }
    }
    const onPointerUp = (event: PointerEvent) => {
      if (moved.x <= 10 && moved.y <= 10) event.preventDefault()
      else if (!element.contains(event.target as Node)) select.setOpen(false)
      document.removeEventListener('pointermove', onPointerMove)
      select.triggerPointerDownPosition = null
    }
    if (start) {
      document.addEventListener('pointermove', onPointerMove)
      document.addEventListener('pointerup', onPointerUp, { capture: true, once: true })
    }

    const close = () => select.setOpen(false)
    window.addEventListener('blur', close)
    window.addEventListener('resize', close)

    const releaseGuards = addFocusGuards()
    const undoInert: Undo = inertOthers(state.wrapper ?? element)
    let scope: FocusScopeHandle | undefined = createFocusScope(element, {
      trapped: true,
      loop: false,
      // Focus goes to the selected option once the content is placed, not to its first element.
      onMountAutoFocus: event => event.preventDefault(),
      onUnmountAutoFocus: event => content.closeAutoFocus(event),
    })

    registerDestructor(this, () => {
      element.removeEventListener('keydown', onKeyDown)
      element.removeEventListener('contextmenu', onContextMenu)
      document.removeEventListener('pointermove', onPointerMove)
      document.removeEventListener('pointerup', onPointerUp, { capture: true })
      window.removeEventListener('blur', close)
      window.removeEventListener('resize', close)
      // The page stops being inert first, so focus can go back to the trigger.
      undoInert()
      scope?.destroy()
      scope = undefined
      releaseGuards()
      state.typeahead.dispose()
      if (!named) element.removeAttribute('aria-labelledby')
      if (!ownTabindex) element.removeAttribute('tabindex')
      restoreProperties()
      restoreStyles()
      if (state.content === element) state.content = null
    })
  }
}

interface PlaceSignature {
  Element: HTMLElement
  Args: { Named: { content: SelectContent } }
}

/**
 * Places the content once the top layer shows it, and focuses the selected option: Radix's
 * `onPlaced`. On the item-aligned wrapper it also works out where the wrapper goes. It goes
 * after `{{topLayer}}` on the element the top layer shows, so it runs after the show.
 */
class Place extends Modifier<PlaceSignature> {
  #installed = false

  override modify(element: HTMLElement, _: [], { content }: { content: SelectContent }): void {
    if (this.#installed) return
    this.#installed = true
    const state = content.state
    let cancelled = false
    registerDestructor(this, () => (cancelled = true))
    if (state.position === 'item-aligned') {
      state.wrapper = element
      const restore = setStyles(element, {
        display: 'flex',
        'flex-direction': 'column',
        position: 'fixed',
        // None of the browser's popover styles: Radix's wrapper is a plain fixed element.
        inset: 'auto',
        width: 'auto',
        height: 'auto',
        margin: '0',
        padding: '0',
        border: '0',
        overflow: 'visible',
        background: 'transparent',
        color: 'inherit',
      })
      registerDestructor(this, restore)
      state.reposition = () => alignItem(content.select, state)
    }
    queueMicrotask(() => {
      if (cancelled) return
      state.reposition?.()
      state.placed()
      if (state.position === 'item-aligned') {
        // The first adjustment to the scroll position mustn't grow the content.
        requestAnimationFrame(() => (state.expandOnScroll = true))
      }
    })
  }
}

/**
 * Radix's `SelectItemAlignedPosition`: puts the content over its trigger, with the selected
 * option's text over the value, as a native select's menu opens, and as tall as fits in the
 * viewport (10px from its edges); the viewport scrolls the option into place.
 */
function alignItem(select: Select, state: SelectContentState): void {
  const trigger = select.triggerRef.current
  const valueNode = select.valueRef.current ?? trigger
  const wrapper = state.wrapper
  const content = state.content
  const viewport = state.viewport.current
  const selected = state.selectedItem
  const selectedItem = selected?.element
  const selectedItemText = selected?.textElement ?? selectedItem
  if (!trigger || !valueNode || !wrapper || !content || !viewport || !selectedItem) return
  if (!selectedItemText) return

  const triggerRect = trigger.getBoundingClientRect()

  // Horizontally
  const contentRect = content.getBoundingClientRect()
  const valueNodeRect = valueNode.getBoundingClientRect()
  const itemTextRect = selectedItemText.getBoundingClientRect()
  const dir = getDirection(trigger, select.args.dir)

  if (dir !== 'rtl') {
    const itemTextOffset = itemTextRect.left - contentRect.left
    const left = valueNodeRect.left - itemTextOffset
    const leftDelta = triggerRect.left - left
    const minContentWidth = triggerRect.width + leftDelta
    const contentWidth = Math.max(minContentWidth, contentRect.width)
    const rightEdge = window.innerWidth - CONTENT_MARGIN
    // It may go off the end edge; never off the start.
    const clampedLeft = clamp(left, [
      CONTENT_MARGIN,
      Math.max(CONTENT_MARGIN, rightEdge - contentWidth),
    ])
    wrapper.style.setProperty('min-width', `${minContentWidth}px`)
    wrapper.style.setProperty('left', `${clampedLeft}px`)
  } else {
    const itemTextOffset = contentRect.right - itemTextRect.right
    const right = window.innerWidth - valueNodeRect.right - itemTextOffset
    const rightDelta = window.innerWidth - triggerRect.right - right
    const minContentWidth = triggerRect.width + rightDelta
    const contentWidth = Math.max(minContentWidth, contentRect.width)
    const leftEdge = window.innerWidth - CONTENT_MARGIN
    const clampedRight = clamp(right, [
      CONTENT_MARGIN,
      Math.max(CONTENT_MARGIN, leftEdge - contentWidth),
    ])
    wrapper.style.setProperty('min-width', `${minContentWidth}px`)
    wrapper.style.setProperty('right', `${clampedRight}px`)
  }

  // Vertically
  const items = select.items
  const availableHeight = window.innerHeight - CONTENT_MARGIN * 2
  const itemsHeight = viewport.scrollHeight

  const contentStyles = getComputedStyle(content)
  const contentBorderTopWidth = Number.parseInt(contentStyles.borderTopWidth, 10)
  const contentPaddingTop = Number.parseInt(contentStyles.paddingTop, 10)
  const contentBorderBottomWidth = Number.parseInt(contentStyles.borderBottomWidth, 10)
  const contentPaddingBottom = Number.parseInt(contentStyles.paddingBottom, 10)
  const fullContentHeight =
    contentBorderTopWidth +
    contentPaddingTop +
    itemsHeight +
    contentPaddingBottom +
    contentBorderBottomWidth
  const minContentHeight = Math.min(selectedItem.offsetHeight * 5, fullContentHeight)

  const viewportStyles = getComputedStyle(viewport)
  const viewportPaddingTop = Number.parseInt(viewportStyles.paddingTop, 10)
  const viewportPaddingBottom = Number.parseInt(viewportStyles.paddingBottom, 10)

  const topEdgeToTriggerMiddle = triggerRect.top + triggerRect.height / 2 - CONTENT_MARGIN
  const triggerMiddleToBottomEdge = availableHeight - topEdgeToTriggerMiddle

  const selectedItemHalfHeight = selectedItem.offsetHeight / 2
  const itemOffsetMiddle = selectedItem.offsetTop + selectedItemHalfHeight
  const contentTopToItemMiddle = contentBorderTopWidth + contentPaddingTop + itemOffsetMiddle
  const itemMiddleToContentBottom = fullContentHeight - contentTopToItemMiddle

  const willAlignWithoutTopOverflow = contentTopToItemMiddle <= topEdgeToTriggerMiddle

  if (willAlignWithoutTopOverflow) {
    const isLastItem = items.length > 0 && selectedItem === items.at(-1)?.element
    wrapper.style.setProperty('bottom', '0px')
    const viewportOffsetBottom = content.clientHeight - viewport.offsetTop - viewport.offsetHeight
    const clampedTriggerMiddleToBottomEdge = Math.max(
      triggerMiddleToBottomEdge,
      selectedItemHalfHeight +
        // The viewport may have padding at the bottom: include it, so it doesn't scroll.
        (isLastItem ? viewportPaddingBottom : 0) +
        viewportOffsetBottom +
        contentBorderBottomWidth,
    )
    const height = contentTopToItemMiddle + clampedTriggerMiddleToBottomEdge
    wrapper.style.setProperty('height', `${height}px`)
  } else {
    const isFirstItem = items.length > 0 && selectedItem === items[0]?.element
    wrapper.style.setProperty('top', '0px')
    const clampedTopEdgeToTriggerMiddle = Math.max(
      topEdgeToTriggerMiddle,
      contentBorderTopWidth +
        viewport.offsetTop +
        // The viewport may have padding at the top: include it, so it doesn't scroll.
        (isFirstItem ? viewportPaddingTop : 0) +
        selectedItemHalfHeight,
    )
    const height = clampedTopEdgeToTriggerMiddle + itemMiddleToContentBottom
    wrapper.style.setProperty('height', `${height}px`)
    viewport.scrollTop = contentTopToItemMiddle - topEdgeToTriggerMiddle + viewport.offsetTop
  }

  wrapper.style.setProperty('margin', `${CONTENT_MARGIN}px 0`)
  wrapper.style.setProperty('min-height', `${minContentHeight}px`)
  wrapper.style.setProperty('max-height', `${availableHeight}px`)
}

interface ViewportBehaviourSignature {
  Element: HTMLElement
  Args: { Named: { select: Select } }
}

/**
 * The viewport's inline styles (it scrolls up and down, with no scrollbar, and is the items'
 * offset parent), and, in the item-aligned position, growing the content as it scrolls, as
 * Radix's `SelectViewport`.
 */
class ViewportBehaviour extends Modifier<ViewportBehaviourSignature> {
  #installed = false

  override modify(element: HTMLElement, _: [], { select }: { select: Select }): void {
    if (this.#installed) return
    this.#installed = true
    const state = select.content
    const restore = setStyles(element, {
      position: 'relative',
      flex: '1',
      overflow: 'hidden auto',
      // Radix hides the scrollbar with a <style>; the CSSOM does it here, which a strict
      // Content Security Policy allows.
      'scrollbar-width': 'none',
    })
    state?.viewport.set(element)
    let previousScrollTop = 0
    const onScroll = () => {
      const wrapper = state?.wrapper
      if (state?.expandOnScroll && wrapper) {
        const scrolledBy = Math.abs(previousScrollTop - element.scrollTop)
        if (scrolledBy > 0) {
          const availableHeight = window.innerHeight - CONTENT_MARGIN * 2
          const cssMinHeight = Number.parseFloat(wrapper.style.minHeight)
          const cssHeight = Number.parseFloat(wrapper.style.height)
          const previousHeight = Math.max(cssMinHeight, cssHeight)
          if (previousHeight < availableHeight) {
            const nextHeight = previousHeight + scrolledBy
            const clampedNextHeight = Math.min(availableHeight, nextHeight)
            const heightDiff = nextHeight - clampedNextHeight
            wrapper.style.setProperty('height', `${clampedNextHeight}px`)
            if (wrapper.style.bottom === '0px') {
              element.scrollTop = heightDiff > 0 ? heightDiff : 0
              // Keep the content pinned to the bottom.
              wrapper.style.setProperty('justify-content', 'flex-end')
            }
          }
        }
      }
      previousScrollTop = element.scrollTop
      state?.measureScroll()
    }
    element.addEventListener('scroll', onScroll)
    registerDestructor(this, () => {
      element.removeEventListener('scroll', onScroll)
      state?.viewport.release(element)
      restore()
    })
  }
}

interface ValueTextSignature {
  Element: HTMLElement
  Args: { Named: { source: HTMLElement | null | undefined; enabled: boolean } }
}

/**
 * Shows the selected option's text in the value, as Radix portals the ItemText's children into
 * it: copies of its nodes (ids left off), kept up to date as the text changes.
 */
class ValueText extends Modifier<ValueTextSignature> {
  #copies: Node[] = []
  #observer: MutationObserver | undefined
  #source: HTMLElement | null | undefined
  #element: HTMLElement | undefined

  override modify(
    element: HTMLElement,
    _: [],
    { source, enabled }: ValueTextSignature['Args']['Named'],
  ): void {
    if (!this.#element) {
      this.#element = element
      registerDestructor(this, () => this.#clear())
    }
    const next = enabled ? source : null
    if (next === this.#source && this.#copies.every(copy => copy.parentNode === element)) return
    this.#source = next
    this.#observer?.disconnect()
    this.#observer = undefined
    this.#copy()
    if (next) {
      this.#observer = new MutationObserver(() => this.#copy())
      this.#observer.observe(next, { childList: true, subtree: true, characterData: true })
    }
  }

  #copy(): void {
    const element = this.#element
    if (!element) return
    for (const copy of this.#copies) copy.parentNode?.removeChild(copy)
    this.#copies = []
    const source = this.#source
    if (!source) return
    for (const node of source.childNodes) {
      const copy = node.cloneNode(true)
      if (copy instanceof Element) {
        copy.removeAttribute('id')
        for (const inner of copy.querySelectorAll('[id]')) inner.removeAttribute('id')
      }
      element.append(copy)
      this.#copies.push(copy)
    }
  }

  #clear(): void {
    this.#observer?.disconnect()
    for (const copy of this.#copies) copy.parentNode?.removeChild(copy)
    this.#copies = []
  }
}

/** The value's `pointer-events: none`, as Radix's, through the CSSOM. */
const noPointerEvents = modifier((element: HTMLElement) => {
  return setStyles(element, { 'pointer-events': 'none' })
})

/** The scroll buttons' `flex-shrink: 0`, as Radix's. */
const noShrink = modifier((element: HTMLElement) => {
  return setStyles(element, { 'flex-shrink': '0' })
})

interface BubbleSelectSignature {
  Element: HTMLSelectElement
  Args: { Named: { value: string } }
}

/**
 * Radix's `SelectBubbleInput`: the hidden native `<select>` follows the value, and tells the
 * form when it changes (`change`, bubbling), as a user's choice would.
 */
class BubbleSelect extends Modifier<BubbleSelectSignature> {
  #previous: string | undefined
  #installed = false

  override modify(element: HTMLSelectElement, _: [], { value }: { value: string }): void {
    if (!this.#installed) {
      this.#installed = true
      this.#previous = value
      const restore = setStyles(element, {
        position: 'absolute',
        border: '0',
        width: '1px',
        height: '1px',
        padding: '0',
        margin: '-1px',
        overflow: 'hidden',
        clip: 'rect(0, 0, 0, 0)',
        'white-space': 'nowrap',
        'word-wrap': 'normal',
      })
      registerDestructor(this, restore)
      // Once its options have rendered.
      queueMicrotask(() => (element.value = value))
      return
    }
    if (this.#previous === value) return
    this.#previous = value
    queueMicrotask(() => {
      element.value = value
      element.dispatchEvent(new Event('change', { bubbles: true }))
    })
  }
}

// ----- The parts -----------------------------------------------------------------------------

export interface SelectPartSignature<E extends Element> {
  Args: {
    /** The part's modifier, bound by the select. */
    part: PartModifier
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** A `<button type="button">`, or `@as`, that opens the select: Radix's `Select.Trigger`. */
const SelectTrigger: TOC<SelectPartSignature<HTMLButtonElement>> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
</template>

/** A `<span>` beside the value, hidden from assistive technology: Radix's `Select.Icon`, `▼` by default. */
const SelectIcon: TOC<SelectPartSignature<HTMLSpanElement>> = <template>
  <As @as={{@as}} @tag="span" aria-hidden="true" ...attributes {{@part}}>
    {{~#if (has-block)}}{{yield}}{{else}}▼{{/if~}}
  </As>
</template>

/** A `<div>` that labels its group: Radix's `Select.Label`. */
const SelectLabel: TOC<SelectPartSignature<HTMLDivElement>> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@part}}>{{yield}}</As>
</template>

/** A `<div>` between options, hidden from assistive technology: Radix's `Select.Separator`. */
const SelectSeparator: TOC<SelectPartSignature<HTMLDivElement>> = <template>
  <As @as={{@as}} @tag="div" aria-hidden="true" ...attributes {{@part}}>{{yield}}</As>
</template>

export interface SelectValueSignature {
  Args: {
    /** @internal Bound by the select. */
    select: Select
    /** What it shows while no option is chosen. */
    placeholder?: string
    /** The tag to render instead of `span`. */
    as?: TagName
  }
  /** Your own content for the chosen value, in place of the option's text. */
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/**
 * The chosen option's text, or the placeholder: Radix's `Select.Value`, a `<span>` that ignores
 * the pointer. With a block of its own it shows that instead of the option's text.
 */
class SelectValue extends Component<SelectValueSignature> {
  get showsPlaceholder(): boolean {
    return showsPlaceholder(this.args.select.value)
  }

  <template>
    <As
      @as={{@as}}
      @tag="span"
      ...attributes
      {{@select.valuePart}}
      {{noPointerEvents}}
      {{ValueText
        source=@select.selectedItem.textElement
        enabled=(if this.showsPlaceholder false (if (has-block) false true))
      }}
    >
      {{~#if this.showsPlaceholder}}{{@placeholder}}{{else if (has-block)}}{{yield}}{{/if~}}
    </As>
  </template>
}

export interface SelectViewportSignature {
  Args: {
    /** @internal Bound by the select. */
    select: Select
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The scrolling part of the content, around the options: Radix's `Select.Viewport`. */
const SelectViewport: TOC<SelectViewportSignature> = <template>
  <As
    @as={{@as}}
    @tag="div"
    role="presentation"
    data-radix-select-viewport=""
    ...attributes
    {{@select.viewportPart}}
    {{ViewportBehaviour select=@select}}
  >{{yield}}</As>
</template>

export interface SelectGroupSignature {
  Args: {
    /** @internal Bound by the select. */
    select: Select
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** Options that belong together, `role="group"`, named by its Label: Radix's `Select.Group`. */
const SelectGroup: TOC<SelectGroupSignature> = <template>
  <As @as={{@as}} @tag="div" role="group" ...attributes {{@select.groupPart}}>{{yield}}</As>
</template>

export interface SelectScrollButtonSignature {
  Args: {
    /** @internal Bound by the select. */
    select: Select
    /** @internal Which way it scrolls. */
    direction: 'up' | 'down'
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  /** Its icon. */
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * Shown while the viewport can scroll its way: hovering or pressing it scrolls an option's
 * height every 50ms. Radix's `Select.ScrollUpButton` and `ScrollDownButton`, hidden from
 * assistive technology (the keyboard scrolls the options into view).
 */
class SelectScrollButton extends Component<SelectScrollButtonSignature> {
  #timer: ReturnType<typeof setInterval> | undefined

  constructor(owner: Owner, args: SelectScrollButtonSignature['Args']) {
    super(owner, args)
    registerDestructor(this, () => this.stop())
  }

  get state(): SelectContentState | undefined {
    const select = this.args.select
    return select.isOpen ? (select.content ?? undefined) : undefined
  }

  get isShown(): boolean {
    const state = this.state
    if (!state) return false
    return this.args.direction === 'up' ? state.canScrollUp : state.canScrollDown
  }

  scroll = (): void => {
    const state = this.state
    const viewport = state?.viewport.current
    const item = state?.selectedItem?.element
    if (!viewport || !item) return
    const step = item.offsetHeight
    viewport.scrollTop += this.args.direction === 'up' ? -step : step
  }

  start = (): void => {
    this.#timer ??= setInterval(this.scroll, 50)
  }

  stop = (): void => {
    if (this.#timer === undefined) return
    clearInterval(this.#timer)
    this.#timer = undefined
  }

  onPointerMove = (): void => {
    this.state?.itemLeft()
    this.start()
  }

  shown = modifier(() => {
    const state = this.state
    // It pushes the viewport: keep the focused option in view, and place the content again.
    const active = document.activeElement
    if (active instanceof HTMLElement && this.args.select.items.some(i => i.element === active)) {
      active.scrollIntoView({ block: 'nearest' })
    }
    queueMicrotask(() => state?.scrollButtonShown())
    return () => this.stop()
  })

  <template>
    {{#if this.isShown}}
      <As
        @as={{@as}}
        @tag="div"
        aria-hidden="true"
        data-test-jn-part="scroll-{{@direction}}-button"
        ...attributes
        {{noShrink}}
        {{this.shown}}
        {{on "pointerdown" this.start}}
        {{on "pointermove" this.onPointerMove}}
        {{on "pointerleave" this.stop}}
      >{{yield}}</As>
    {{/if}}
  </template>
}

export interface SelectArrowSignature {
  Args: {
    /** @internal Bound by the select. */
    select: Select
    /** Its width, in pixels. Default 10. */
    width?: number
    /** Its height, in pixels. Default 5. */
    height?: number
  }
  Blocks: { default: [] }
  Element: SVGSVGElement
}

/** Radix's `Select.Arrow`: an arrow pointing at the trigger, in the `popper` position only. */
const SelectArrow: TOC<SelectArrowSignature> = <template>
  {{#if @select.showsArrow}}
    {{#if (has-block)}}
      <PopperArrow @arrow={{@select.arrowRef}} @width={{@width}} @height={{@height}} ...attributes>
        {{yield}}
      </PopperArrow>
    {{else}}
      <PopperArrow
        @arrow={{@select.arrowRef}}
        @width={{@width}}
        @height={{@height}}
        ...attributes
      />
    {{/if}}
  {{/if}}
</template>

// ----- Items ---------------------------------------------------------------------------------

export interface SelectItemSignature {
  Args: {
    /** @internal Bound by the select. */
    select: Select
    /** The option's value: what `@value` and `@onValueChange` carry. It can't be `''`. */
    value: string
    /** Makes it impossible to choose. */
    disabled?: boolean
    /** The text typeahead matches, when the option's text isn't plain (icons, extra text). */
    textValue?: string
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [SelectItemBlockParams] }
  Element: HTMLDivElement
}

/** What an option yields: its text and its indicator, bound to it. */
export interface SelectItemBlockParams {
  /** The option's text: what the value shows when it is chosen, and what names the option. */
  ItemText: WithBoundArgs<typeof SelectItemText, 'item'>
  /** Shown only while the option is chosen, such as a check mark. */
  ItemIndicator: WithBoundArgs<typeof SelectItemIndicator, 'item'>
  /** Whether it is the chosen option. */
  isSelected: boolean
  /** Whether it has focus (Radix's `data-highlighted`). */
  isHighlighted: boolean
}

/**
 * One option, `role="option"`: Radix's `Select.Item`. A mouse chooses it on release (so a press
 * on the trigger can slide to an option and let go), a touch or pen on the click; Enter or
 * Space chooses the focused one. Focus follows the mouse.
 */
export class SelectItem extends Component<SelectItemSignature> {
  textRef = new ElementRef()
  @tracked isFocused = false
  element!: HTMLElement
  #pointerType = 'touch'

  get select(): Select {
    return this.args.select
  }

  get value(): string {
    return this.args.value
  }

  get isDisabled(): boolean {
    return this.args.disabled ?? false
  }

  get isSelected(): boolean {
    return this.select.value === this.args.value
  }

  get textElement(): HTMLElement | null {
    return this.textRef.value
  }

  /** The text typeahead matches: `@textValue`, or the ItemText's, trimmed. */
  get textValue(): string {
    return this.args.textValue ?? (this.textRef.current?.textContent ?? '').trim()
  }

  get textId(): string {
    return idFor(this, 'text')
  }

  choose = (): void => {
    if (this.isDisabled) return
    this.select.setValue(this.args.value)
    this.select.setOpen(false)
  }

  part: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      role: 'option',
      'aria-labelledby': this.textRef.value ? this.textId : undefined,
      'data-highlighted': this.isFocused,
      // Only while focused, as Radix's: VoiceOver stutters otherwise.
      'aria-selected': String(this.isSelected && this.isFocused),
      'data-state': this.isSelected ? 'checked' : 'unchecked',
      'aria-disabled': this.isDisabled ? 'true' : undefined,
      'data-disabled': this.isDisabled,
      tabindex: this.isDisabled ? undefined : '-1',
      'data-test-jn-part': 'option',
      'data-test-jn-value': this.args.value,
    },
    on: {
      focus: () => (this.isFocused = true),
      blur: () => (this.isFocused = false),
      click: () => {
        // A mouse chooses on release; a touch or pen on the click.
        if (this.#pointerType !== 'mouse') this.choose()
      },
      pointerup: () => {
        if (this.#pointerType === 'mouse') this.choose()
      },
      pointerdown: event => (this.#pointerType = event.pointerType),
      pointermove: event => {
        this.#pointerType = event.pointerType
        if (this.isDisabled) this.select.content?.itemLeft()
        else if (event.pointerType === 'mouse') this.element.focus({ preventScroll: true })
      },
      pointerleave: () => {
        if (this.element === document.activeElement) this.select.content?.itemLeft()
      },
      keydown: event => {
        const typing = this.select.content?.typeahead.isTyping ?? false
        if (typing && event.key === ' ') return
        if (SELECTION_KEYS.includes(event.key)) this.choose()
        // Space mustn't scroll the page.
        if (event.key === ' ') event.preventDefault()
      },
    },
    element: element => {
      this.element = element
      return this.select.registerItem(this)
    },
  }))

  text: PartModifier = part<HTMLElement>(() => ({
    attributes: { id: this.textId, 'data-test-jn-part': 'option-text' },
    element: element => {
      this.textRef.set(element)
      this.select.itemsChanged()
      return () => {
        this.textRef.release(element)
        this.select.itemsChanged()
      }
    },
  }))

  <template>
    <As @as={{@as}} @tag="div" ...attributes {{this.part}}>
      {{yield
        (hash
          ItemText=(component SelectItemText item=this)
          ItemIndicator=(component SelectItemIndicator item=this)
          isSelected=this.isSelected
          isHighlighted=this.isFocused
        )
      }}
    </As>
  </template>
}

export interface SelectItemTextSignature {
  Args: {
    /** @internal Bound by its option. */
    item: SelectItem
    /** The tag to render instead of `span`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/** Radix's `Select.ItemText`: the option's text, which names it and which the value shows. */
const SelectItemText: TOC<SelectItemTextSignature> = <template>
  <As @as={{@as}} @tag="span" ...attributes {{@item.text}}>{{yield}}</As>
</template>

export interface SelectItemIndicatorSignature {
  Args: {
    /** @internal Bound by its option. */
    item: SelectItem
    /** The tag to render instead of `span`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/** Radix's `Select.ItemIndicator`: rendered while its option is chosen, hidden from assistive technology. */
const SelectItemIndicator: TOC<SelectItemIndicatorSignature> = <template>
  {{#if @item.isSelected}}
    <As
      @as={{@as}}
      @tag="span"
      aria-hidden="true"
      data-test-jn-part="option-indicator"
      ...attributes
    >{{yield}}</As>
  {{/if}}
</template>

// ----- Content -------------------------------------------------------------------------------

export interface SelectContentSignature {
  Args: SelectContentArgs & {
    /** @internal Bound by the select. */
    select: Select
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The listbox: Radix's `Select.Content`. While the select is closed its options still render,
 * outside the page (as Radix renders them into a fragment), so the value can show the chosen
 * option's text and typeahead on the trigger can find the options. While it is open it is in
 * the browser's top layer, over its trigger (`item-aligned`) or anchored below it (`popper`),
 * with focus trapped inside and the rest of the page inert.
 */
export class SelectContent extends Component<SelectContentSignature> {
  /** Where the closed content's options render: an element outside the page. */
  readonly offPage: HTMLElement = document.createElement('div')

  get select(): Select {
    return this.args.select
  }

  get position(): SelectPosition {
    return this.args.position ?? 'item-aligned'
  }

  get isPopper(): boolean {
    return this.position === 'popper'
  }

  get anchorOptions(): AnchorOptions {
    const own = this.isPopper ? this.args : {}
    return popperOptions(own, {}, POPPER_DEFAULTS, { arrow: this.select.arrowRef.value })
  }

  #state: SelectContentState | undefined

  /**
   * The open content's state, made as it opens (the template reads it first thing, so the parts
   * inside see it) and forgotten when it closes. A new position starts afresh.
   */
  get state(): SelectContentState {
    return this.ensureState()
  }

  ensureState = (): SelectContentState => {
    let state = this.#state
    if (!state || state.position !== this.position) {
      state = this.#state = new SelectContentState(this.select, this.position)
      this.select.content = state
    }
    return state
  }

  opened = modifier(() => {
    const state = this.#state
    return () => {
      if (this.#state !== state) return
      this.#state = undefined
      if (this.select.content === state) this.select.content = null
    }
  })

  closeAutoFocus(event: Event): void {
    this.args.onCloseAutoFocus?.(event)
    if (event.defaultPrevented) return
    event.preventDefault()
    this.select.triggerRef.current?.focus({ preventScroll: true })
  }

  /** Radix's content keyboard: no Tab, typeahead, and the arrow keys, Home and End between options. */
  keyDown(event: KeyboardEvent): void {
    if (event.defaultPrevented) return
    const state = this.select.content
    if (!state) return
    // A select isn't navigated with Tab.
    if (event.key === 'Tab') event.preventDefault()
    if (isTypeaheadKey(event)) {
      const items = this.select.items.filter(item => !item.isDisabled)
      const current = items.find(item => item.element === document.activeElement)
      const search = state.typeahead.type(event.key)
      const next = getNextMatch(items, search, current, item => item.textValue)
      if (next) next.element.focus()
    }
    if (['ArrowUp', 'ArrowDown', 'Home', 'End'].includes(event.key)) {
      let candidates = this.select.items.filter(item => !item.isDisabled).map(item => item.element)
      if (['ArrowUp', 'End'].includes(event.key)) candidates = candidates.slice().reverse()
      if (['ArrowUp', 'ArrowDown'].includes(event.key)) {
        const index = candidates.indexOf(event.target as HTMLElement)
        candidates = candidates.slice(index + 1)
      }
      state.focusFirst(candidates)
      event.preventDefault()
    }
  }

  onEscapeKeyDown = (event: KeyboardEvent): void => this.args.onEscapeKeyDown?.(event)
  onPointerDownOutside = (event: PointerDownOutsideEvent): void =>
    this.args.onPointerDownOutside?.(event)
  // Focus is trapped, but a focusout may still happen: it never closes the select.
  onFocusOutside = (event: Event): void => event.preventDefault()
  dismiss = (): void => this.select.setOpen(false)

  <template>
    {{#if @select.isOpen}}
      {{#let (this.ensureState) as |state|}}{{#if state.select}}{{/if}}{{/let}}
      {{#if this.isPopper}}
        <As
          @as={{@as}}
          @tag="div"
          ...attributes
          {{this.opened}}
          {{@select.contentPart}}
          {{ContentBehaviour content=this}}
          {{dismissable
            onDismiss=this.dismiss
            onEscapeKeyDown=this.onEscapeKeyDown
            onPointerDownOutside=this.onPointerDownOutside
            onFocusOutside=this.onFocusOutside
            disableOutsidePointerEvents=true
          }}
          {{scrollLock}}
          {{topLayer}}
          {{anchorContent @select.triggerRef.value this.anchorOptions}}
          {{Place content=this}}
        >{{yield}}</As>
      {{else}}
        <div
          data-test-jn-part="content-wrapper"
          {{this.opened}}
          {{topLayer}}
          {{Place content=this}}
        >
          <As
            @as={{@as}}
            @tag="div"
            ...attributes
            {{@select.contentPart}}
            {{ContentBehaviour content=this}}
            {{dismissable
              onDismiss=this.dismiss
              onEscapeKeyDown=this.onEscapeKeyDown
              onPointerDownOutside=this.onPointerDownOutside
              onFocusOutside=this.onFocusOutside
              disableOutsidePointerEvents=true
            }}
            {{scrollLock}}
          >{{yield}}</As>
        </div>
      {{/if}}
    {{else}}
      {{#in-element this.offPage insertBefore=null}}
        <div>{{yield}}</div>
      {{/in-element}}
    {{/if}}
  </template>
}

// ----- The select ----------------------------------------------------------------------------

/** What a `<Select>` yields: its parts, the trigger's modifier, and its state. */
export interface SelectBlockParams {
  /** A `<button>` that opens it (`@as` for another tag). For your own element, use `trigger`. */
  Trigger: WithBoundArgs<typeof SelectTrigger, 'part'>
  /** The chosen option's text, or `@placeholder`. Put it inside the trigger. */
  Value: WithBoundArgs<typeof SelectValue, 'select'>
  /** An icon beside the value, `▼` by default. */
  Icon: WithBoundArgs<typeof SelectIcon, 'part'>
  /** The listbox, in the top layer while open. */
  Content: WithBoundArgs<typeof SelectContent, 'select'>
  /** The scrolling part of the content, around the options. */
  Viewport: WithBoundArgs<typeof SelectViewport, 'select'>
  /** One option: `<s.Item @value="apple" as |item|><item.ItemText>Apple</item.ItemText></s.Item>`. */
  Item: WithBoundArgs<typeof SelectItem, 'select'>
  /** Options that belong together. */
  Group: WithBoundArgs<typeof SelectGroup, 'select'>
  /** The label of the group it is in. */
  Label: WithBoundArgs<typeof SelectLabel, 'part'>
  /** A line between options. */
  Separator: WithBoundArgs<typeof SelectSeparator, 'part'>
  /** Shown while the options can scroll up. */
  ScrollUpButton: WithBoundArgs<typeof SelectScrollButton, 'select' | 'direction'>
  /** Shown while the options can scroll down. */
  ScrollDownButton: WithBoundArgs<typeof SelectScrollButton, 'select' | 'direction'>
  /** An arrow pointing at the trigger, in the `popper` position. */
  Arrow: WithBoundArgs<typeof SelectArrow, 'select'>
  /** Makes your own element or component the trigger: `<Button {{s.trigger}}>`. */
  trigger: PartModifier
  /** The chosen value, or `''`. */
  value: string
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
  /** Chooses a value. */
  setValue: (value: string) => void
}

export interface SelectSignature {
  Args: SelectArgs
  Blocks: { default: [SelectBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * Displays a list of options for the user to pick from, triggered by a button: Radix's Select,
 * which shadcn's is built on. It renders no box of its own, and yields its parts:
 *
 *   <Select @defaultValue="apple" as |s|>
 *     <s.Trigger aria-label="Fruit"><s.Value @placeholder="Select a fruit" /><s.Icon /></s.Trigger>
 *     <s.Content>
 *       <s.Viewport>
 *         <s.Item @value="apple" as |item|><item.ItemText>Apple</item.ItemText></s.Item>
 *         <s.Item @value="banana" as |item|><item.ItemText>Banana</item.ItemText></s.Item>
 *       </s.Viewport>
 *     </s.Content>
 *   </Select>
 *
 * Its value and open state are its own, or yours (`@value` with `@onValueChange`, `@open` with
 * `@onOpenChange`; `@defaultValue` and `@defaultOpen` to start). The trigger is a `combobox`
 * button: a mouse opens it on press, the keyboard on Space, Enter or the arrows, and typing a
 * letter on it chooses the next option starting with it. Inside a form, a hidden native
 * `<select>` named `@formName` carries the value.
 */
export class Select extends Component<SelectSignature> {
  openState = controllable(this, 'open', false)
  valueState = controllable(this, 'value', '')
  triggerRef = new ElementRef()
  valueRef = new ElementRef()
  arrowRef = new ElementRef()
  /** The open content's state, while it is open. */
  @tracked content: SelectContentState | null = null
  /** Where the press on the trigger that opened it went down, in page coordinates. */
  triggerPointerDownPosition: { x: number; y: number } | null = null
  /** The trigger's typeahead, which chooses while closed. */
  typeahead = new Typeahead()

  #items = new Set<SelectItem>()
  @tracked private itemsVersion = 0
  #bumping = false

  constructor(owner: Owner, args: SelectArgs) {
    super(owner, args)
    registerDestructor(this, () => this.typeahead.dispose())
  }

  get id(): string {
    return idFor(this)
  }

  get contentId(): string {
    return idFor(this, 'content')
  }

  get isOpen(): boolean {
    return this.openState.value
  }

  get value(): string {
    return this.valueState.value
  }

  get isDisabled(): boolean {
    return this.args.disabled ?? false
  }

  get state(): 'open' | 'closed' {
    return this.isOpen ? 'open' : 'closed'
  }

  get showsArrow(): boolean {
    return this.isOpen && this.content?.position === 'popper'
  }

  /** The options rendered now, in document order. */
  get items(): SelectItem[] {
    return [...this.#items].filter(item => item.element).sort(byDocumentOrder)
  }

  /** The options, tracked: for what renders from them (the native options, the value's text). */
  get trackedItems(): SelectItem[] {
    void this.itemsVersion
    return this.items
  }

  get selectedItem(): SelectItem | undefined {
    const value = this.value
    if (showsPlaceholder(value)) return undefined
    return this.trackedItems.find(item => item.value === value)
  }

  /** The hidden native `<select>`'s options: one for each option, and an empty one while none is chosen. */
  get nativeOptions(): Array<{
    value: string
    text: string
    disabled: boolean
    selected: boolean
  }> {
    return this.trackedItems.map(item => ({
      value: item.value,
      text: item.textElement?.textContent ?? item.textValue,
      disabled: item.isDisabled,
      selected: item.value === this.value,
    }))
  }

  /** Whether it takes part in a form, so needs the hidden `<select>`: inside one, or given `@form`. */
  get isFormControl(): boolean {
    const trigger = this.triggerRef.value
    return Boolean(this.args.form) || Boolean(trigger?.closest('form'))
  }

  registerItem(item: SelectItem): () => void {
    this.#items.add(item)
    this.itemsChanged()
    return () => {
      this.#items.delete(item)
      this.itemsChanged()
    }
  }

  /** Re-renders what depends on the options, after the render that changed them. */
  itemsChanged(): void {
    if (this.#bumping) return
    this.#bumping = true
    queueMicrotask(() => {
      this.#bumping = false
      this.itemsVersion += 1
    })
  }

  setOpen = (open: boolean): void => this.openState.set(open)

  setValue = (value: string): void => this.valueState.set(value)

  /** Radix's `handleOpen`: opens it unless disabled, and starts a fresh typeahead. */
  openFrom(event?: PointerEvent | MouseEvent): void {
    if (!this.isDisabled) {
      this.setOpen(true)
      this.typeahead.reset()
    }
    if (event) {
      this.triggerPointerDownPosition = {
        x: Math.round(event.pageX),
        y: Math.round(event.pageY),
      }
    }
  }

  #pointerType = 'touch'

  trigger: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      role: 'combobox',
      'aria-controls': this.isOpen ? this.contentId : undefined,
      'aria-expanded': String(this.isOpen),
      'aria-required': this.args.required ? 'true' : undefined,
      'aria-autocomplete': 'none',
      dir: this.args.dir,
      'data-state': this.state,
      disabled: this.isDisabled,
      'data-disabled': this.isDisabled,
      'data-placeholder': showsPlaceholder(this.value),
      'data-test-jn-part': 'trigger',
    },
    on: {
      click: event => {
        // Safari doesn't focus a button a label's click presses; Radix focuses it.
        ;(event.currentTarget as HTMLElement).focus()
        // A touch or pen opens it on the click.
        if (this.#pointerType !== 'mouse') this.openFrom(event)
      },
      pointerdown: event => {
        this.#pointerType = event.pointerType
        // No implicit pointer capture: the release goes to whatever is under the pointer.
        const target = event.target as HTMLElement
        if (target.hasPointerCapture?.(event.pointerId))
          target.releasePointerCapture(event.pointerId)
        // The left button only, without Ctrl (a right click on macOS), and not a touch, which
        // might be a scroll.
        if (event.button === 0 && !event.ctrlKey && event.pointerType === 'mouse') {
          this.openFrom(event)
          // Focus goes to the chosen option, not the trigger.
          event.preventDefault()
        }
      },
      keydown: event => {
        const typing = this.typeahead.isTyping
        const modifier = event.ctrlKey || event.altKey || event.metaKey
        if (!modifier && event.key.length === 1) this.typeAhead(event.key)
        if (typing && event.key === ' ') return
        if (OPEN_KEYS.includes(event.key)) {
          this.openFrom()
          event.preventDefault()
        }
      },
    },
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

  /** Typing on the closed trigger chooses the next option starting with what was typed. */
  typeAhead(key: string): void {
    const items = this.items.filter(item => !item.isDisabled)
    const current = items.find(item => item.value === this.value)
    const next = getNextMatch(items, this.typeahead.type(key), current, item => item.textValue)
    if (next) this.setValue(next.value)
  }

  valuePart: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'value' },
    element: element => {
      this.valueRef.set(element)
      return () => this.valueRef.release(element)
    },
  }))

  icon: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'icon' },
  }))

  contentPart: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      id: this.contentId,
      role: 'listbox',
      'data-state': this.state,
      dir: this.args.dir,
      'data-test-jn-part': 'content',
      'data-test-jn-owner': this.id,
    },
  }))

  viewportPart: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'viewport' },
  }))

  groupPart: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'group' },
  }))

  /** A label names the group it is in, as Radix's `Select.Label` does its `Select.Group`. */
  label: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'label' },
    element: element => {
      const restoreId = ensureId(element, idFor(element, 'label'))
      const group = element.closest('[role="group"]')
      const labelled = group && !group.hasAttribute('aria-labelledby')
      if (labelled) group.setAttribute('aria-labelledby', element.id)
      return () => {
        if (labelled && group.getAttribute('aria-labelledby') === element.id) {
          group.removeAttribute('aria-labelledby')
        }
        restoreId()
      }
    },
  }))

  separator: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'separator' },
  }))

  <template>
    <div
      id={{this.id}}
      data-test-jn="select"
      data-test-jn-name={{@name}}
      data-test-jn-value={{this.value}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Trigger=(component SelectTrigger part=this.trigger)
          Value=(component SelectValue select=this)
          Icon=(component SelectIcon part=this.icon)
          Content=(component SelectContent select=this)
          Viewport=(component SelectViewport select=this)
          Item=(component SelectItem select=this)
          Group=(component SelectGroup select=this)
          Label=(component SelectLabel part=this.label)
          Separator=(component SelectSeparator part=this.separator)
          ScrollUpButton=(component SelectScrollButton select=this direction="up")
          ScrollDownButton=(component SelectScrollButton select=this direction="down")
          Arrow=(component SelectArrow select=this)
          trigger=this.trigger
          value=this.value
          isOpen=this.isOpen
          setOpen=this.setOpen
          setValue=this.setValue
        )
      }}
      {{#if this.isFormControl}}
        <select
          aria-hidden="true"
          tabindex="-1"
          name={{@formName}}
          autocomplete={{@autoComplete}}
          required={{@required}}
          disabled={{@disabled}}
          form={{@form}}
          data-test-jn-part="native-select"
          {{BubbleSelect value=this.value}}
          {{on "change" this.autofill}}
        >
          {{#if this.showsEmptyOption}}<option value=""></option>{{/if}}
          {{! Named native, not option: a block param named option would turn <option> into a call to it. }}
          {{#each this.nativeOptions key="value" as |native|}}
            <option
              value={{native.value}}
              disabled={{native.disabled}}
              selected={{native.selected}}
            >{{native.text}}</option>
          {{/each}}
        </select>
      {{/if}}
    </div>
  </template>

  get showsEmptyOption(): boolean {
    return showsPlaceholder(this.value)
  }

  /** The browser's autofill chose an option of the native `<select>`. */
  autofill = (event: Event): void => {
    const value = (event.target as HTMLSelectElement).value
    if (value !== this.value) this.setValue(value)
  }
}

export default Select
