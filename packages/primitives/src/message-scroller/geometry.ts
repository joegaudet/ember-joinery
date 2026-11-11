// The message scroller's measurements, ported from @shadcn/react's message-scroller/geometry.ts
// (shadcn-ui/ui@8ab2771). One change: every distance read off the screen
// (`getBoundingClientRect()`) is turned back into CSS pixels, the unit of `scrollTop`, by the
// viewport's scale, so a scroller inside a scaled ancestor (a `transform: scale()`, such as the
// test container's) lands where it would unscaled. Unscaled, the scale is 1 and the numbers are
// upstream's.

/** The edges the viewport can still scroll toward. */
export interface MessageScrollerScrollable {
  /** It can scroll toward the start: content is hidden above. */
  start: boolean
  /** It can scroll toward the end: content is hidden below. */
  end: boolean
}

/** Where the reader is in the transcript. */
export interface MessageScrollerVisibilityState {
  /**
   * The anchored turn the reader is in (the last `@scrollAnchor` row at or above the reading
   * line), or `null`. It stays set after that row scrolls above the viewport.
   */
  currentAnchorId: string | null
  /** The `@messageId` of each row in the viewport, in document order. */
  visibleMessageIds: string[]
}

/** Where a command lines its target up in the viewport. */
export type MessageScrollerScrollAlign = 'start' | 'center' | 'end' | 'nearest'

/** Two fractional scroll positions this close are the same: zoom and HiDPI rounding drift. */
export const SCROLL_POSITION_EPSILON = 0.5

export const EMPTY_SCROLLABLE: MessageScrollerScrollable = Object.freeze({
  start: false,
  end: false,
})

const EMPTY_IDS: string[] = []

export const EMPTY_VISIBILITY: MessageScrollerVisibilityState = Object.freeze({
  currentAnchorId: null,
  visibleMessageIds: EMPTY_IDS,
})

/**
 * How much the screen scales the viewport: an on-screen length (`getBoundingClientRect()`) is
 * this many times its CSS length. 1 unless an ancestor transforms it.
 */
export function getScale(viewport: HTMLElement): number {
  const height = viewport.offsetHeight
  if (!height) return 1
  const scale = viewport.getBoundingClientRect().height / height
  return Number.isFinite(scale) && scale > 0 ? scale : 1
}

export function getMessageScrollerScrollable({
  content,
  scrollEdgeThreshold,
  spacer,
  viewport,
}: {
  content: HTMLElement | null
  scrollEdgeThreshold: number
  spacer: HTMLElement | null
  viewport: HTMLElement | null
}): MessageScrollerScrollable {
  if (!viewport || !content) return EMPTY_SCROLLABLE
  const contentBottom = getContentBottom({ content, spacer, viewport })
  return {
    start: viewport.scrollTop > scrollEdgeThreshold,
    end: contentBottom - viewport.scrollTop - viewport.clientHeight > scrollEdgeThreshold,
  }
}

export function getMessageScrollerVisibilityState({
  content,
  scrollMargin,
  scrollPreviousItemPeek,
  spacer,
  viewport,
  visibleMessageIds,
}: {
  content: HTMLElement | null
  scrollMargin: number
  scrollPreviousItemPeek: number
  spacer: HTMLElement | null
  viewport: HTMLElement | null
  visibleMessageIds: Set<string>
}): MessageScrollerVisibilityState {
  if (!content || !viewport) return EMPTY_VISIBILITY
  const scale = getScale(viewport)
  const viewportRect = viewport.getBoundingClientRect()
  // The reading line sits scrollPreviousItemPeek below scrollMargin: anchored turns land there
  // with the previous turn peeking above. A row only peeking in that band has not been read
  // down to yet, so it counts as neither visible nor current.
  const lineTop = viewportRect.top + (scrollMargin + scrollPreviousItemPeek) * scale
  const trackByLayout = typeof IntersectionObserver === 'undefined'
  const visible: string[] = []
  let currentAnchorId: string | null = null

  // Rows in document order, so the visible ids come out top to bottom.
  for (const item of getMessageScrollerItems(content, spacer)) {
    const messageId = item.dataset['messageId']
    if (!messageId) continue
    const isAnchor = item.dataset['scrollAnchor'] === 'true'
    // Anchors need a rect to place the current line; the others lean on the observer's set
    // (or a rect, where there is no observer).
    const rect = isAnchor || trackByLayout ? item.getBoundingClientRect() : null
    const isVisible =
      trackByLayout && rect
        ? rect.bottom > lineTop && rect.top < viewportRect.bottom
        : visibleMessageIds.has(messageId)
    if (isVisible) visible.push(messageId)
    // Current is the last anchor to have reached the reading line: the turn you scrolled to
    // wins over newer turns lower down, the previous turn peeking above the line has been
    // passed, and it stays current after its header scrolls out of the viewport.
    if (isAnchor && rect && rect.top <= lineTop + SCROLL_POSITION_EPSILON * scale) {
      currentAnchorId = messageId
    }
  }

  if (visible.length === 0 && currentAnchorId === null) return EMPTY_VISIBILITY
  return { currentAnchorId, visibleMessageIds: visible }
}

/** The transcript's rows: every element in the content but the tail spacer. */
export function getMessageScrollerItems(
  content: HTMLElement,
  spacer: HTMLElement | null,
): HTMLElement[] {
  return Array.from(content.children).filter(
    (child): child is HTMLElement => child instanceof HTMLElement && child !== spacer,
  )
}

const isAnchor = (item: HTMLElement | undefined) => item?.dataset['scrollAnchor'] === 'true'

/** The first anchor among the rows from `previousItemCount` on: the ones just appended. */
export function getNewScrollAnchor(
  items: HTMLElement[],
  previousItemCount: number,
): HTMLElement | null {
  for (let index = previousItemCount; index < items.length; index++) {
    if (isAnchor(items[index])) return items[index]!
  }
  return null
}

/** The first anchor that hasn't been placed yet: a row that became an anchor in place. */
export function getUnanchoredScrollAnchor(
  items: HTMLElement[],
  handledAnchors: { has(element: HTMLElement): boolean },
): HTMLElement | null {
  for (const item of items) {
    if (isAnchor(item) && !handledAnchors.has(item)) return item
  }
  return null
}

/** Whether more than one of the rows just appended is an anchor. */
export function hasMultipleNewScrollAnchors(
  items: HTMLElement[],
  previousItemCount: number,
): boolean {
  let count = 0
  for (let index = previousItemCount; index < items.length; index++) {
    if (!isAnchor(items[index])) continue
    count += 1
    if (count > 1) return true
  }
  return false
}

/** The last anchor in the transcript. */
export function getLastScrollAnchor(items: HTMLElement[]): HTMLElement | null {
  for (let index = items.length - 1; index >= 0; index--) {
    if (isAnchor(items[index])) return items[index]!
  }
  return null
}

/** The first row with a `messageId` that shows in the viewport. */
export function getFirstVisibleMessageItem({
  content,
  spacer,
  viewport,
}: {
  content: HTMLElement
  spacer: HTMLElement | null
  viewport: HTMLElement
}): HTMLElement | null {
  const viewportRect = viewport.getBoundingClientRect()
  for (const item of getMessageScrollerItems(content, spacer)) {
    if (!item.dataset['messageId']) continue
    const rect = item.getBoundingClientRect()
    if (rect.bottom > viewportRect.top && rect.top < viewportRect.bottom) return item
  }
  return null
}

/** The `scrollTop` that lines `element` up at `align`, `scrollMargin` from that edge. */
export function getElementScrollTop({
  align,
  element,
  scrollMargin,
  spacer,
  viewport,
}: {
  align: MessageScrollerScrollAlign
  element: HTMLElement
  scrollMargin: number
  spacer: HTMLElement | null
  viewport: HTMLElement
}): number {
  const elementTop = getElementTop(element, viewport)
  const elementHeight = element.getBoundingClientRect().height / getScale(viewport)
  const contentPadding = getContentBlockPadding(spacer)

  if (align === 'center') {
    const insetHeight = Math.max(
      0,
      viewport.clientHeight - contentPadding.start - contentPadding.end,
    )
    return elementTop - contentPadding.start - (insetHeight - elementHeight) / 2 - scrollMargin
  }
  if (align === 'end') {
    return elementTop - viewport.clientHeight + elementHeight + contentPadding.end + scrollMargin
  }
  if (align === 'nearest') {
    const elementBottom = elementTop + elementHeight
    const viewportTop = viewport.scrollTop + contentPadding.start
    const viewportBottom = viewport.scrollTop + viewport.clientHeight - contentPadding.end
    if (elementTop >= viewportTop && elementBottom <= viewportBottom) return viewport.scrollTop
    if (elementTop < viewportTop) return elementTop - contentPadding.start - scrollMargin
    return elementBottom - viewport.clientHeight + contentPadding.end + scrollMargin
  }
  return elementTop - contentPadding.start - scrollMargin
}

/** Where `element` starts in the viewport's scrolled content, in CSS pixels. */
export function getElementTop(element: HTMLElement, viewport: HTMLElement): number {
  return getElementViewportTop(element, viewport) + viewport.scrollTop
}

/** Where `element` starts below the viewport's top edge, in CSS pixels. */
export function getElementViewportTop(element: HTMLElement, viewport: HTMLElement): number {
  const delta = element.getBoundingClientRect().top - viewport.getBoundingClientRect().top
  return delta / getScale(viewport)
}

/** How tall the tail spacer must be for `scrollTop` to be reachable. */
export function getTailSpacerHeight({
  content,
  scrollTop,
  spacer,
  viewport,
}: {
  content: HTMLElement
  scrollTop: number
  spacer: HTMLElement | null
  viewport: HTMLElement
}): number {
  return scrollTop + viewport.clientHeight - getContentBottom({ content, spacer, viewport })
}

/** Where the last row ends in the scrolled content, with the content's padding, spacer aside. */
export function getContentBottom({
  content,
  spacer,
  viewport,
}: {
  content: HTMLElement
  spacer: HTMLElement | null
  viewport: HTMLElement
}): number {
  const items = getMessageScrollerItems(content, spacer)
  const padding = getBlockPadding(content)
  const scale = getScale(viewport)
  const viewportTop = viewport.getBoundingClientRect().top
  const scrollTop = viewport.scrollTop
  let contentBottom = padding.start + padding.end
  for (const item of items) {
    const bottom = (item.getBoundingClientRect().bottom - viewportTop) / scale
    contentBottom = Math.max(contentBottom, bottom + scrollTop + padding.end)
  }
  return contentBottom
}

/** How far the viewport can scroll. */
export function getMaxScrollTop(viewport: HTMLElement): number {
  return Math.max(0, viewport.scrollHeight - viewport.clientHeight)
}

function getBlockPadding(element: HTMLElement): { start: number; end: number } {
  const style = window.getComputedStyle(element)
  return {
    end: readCssPixel(style.paddingBlockEnd || style.paddingBottom),
    start: readCssPixel(style.paddingBlockStart || style.paddingTop),
  }
}

/** The content's block padding, found from the spacer inside it. */
export function getContentBlockPadding(spacer: HTMLElement | null): { start: number; end: number } {
  const content = spacer?.parentElement
  if (!content) return { end: 0, start: 0 }
  return getBlockPadding(content)
}

/** The row gap of a flex container, which the spacer takes back with a negative margin. */
export function getFlexGap(element: HTMLElement | null): number {
  if (!element) return 0
  const style = window.getComputedStyle(element)
  const gap = style.rowGap === 'normal' ? style.gap : style.rowGap
  return readCssPixel(gap)
}

function readCssPixel(value: string | undefined): number {
  if (!value) return 0
  const number = Number.parseFloat(value)
  return Number.isFinite(number) ? number : 0
}
