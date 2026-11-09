import { click, getRootElement, triggerEvent, triggerKeyEvent } from '@ember/test-helpers'
import type { TestHooks } from './test-hooks.ts'

/**
 * Presses Escape where focus is (or on `target`), as a user closing the top layer does. Only
 * the top layer closes.
 */
export async function pressEscape(target?: Element): Promise<void> {
  const where = target ?? document.activeElement ?? document.body
  await triggerKeyEvent(where, 'keydown', 'Escape')
  await triggerKeyEvent(where, 'keyup', 'Escape')
}

export interface PointerOptions {
  /** `mouse` (the default), `pen` or `touch`. A touch dismisses on the click that follows. */
  pointerType?: 'mouse' | 'pen' | 'touch'
}

/**
 * A press on an element the way a pointer makes one: `pointerdown`, then `click()`'s
 * `mousedown`, focus, `mouseup` and `click`, then `pointerup`. `click()` alone sends no
 * pointer events, and the dismiss stack listens for `pointerdown`, as Radix's does.
 */
export async function press(target: Element, { pointerType = 'mouse' }: PointerOptions = {}) {
  await triggerEvent(target, 'pointerdown', { pointerType, isPrimary: true, button: 0 })
  await click(target)
  await triggerEvent(target, 'pointerup', { pointerType, isPrimary: true, button: 0 })
}

/**
 * A press outside every layer: on `target`, or else on the test's root element (outside any
 * layer, which the top layer shows above it).
 */
export async function pressOutside(target?: Element, options?: PointerOptions): Promise<void> {
  const root = getRootElement()
  await press(target ?? (root instanceof Element ? root : root.body), options)
}

/** Whether an element is in the browser's top layer now: an open popover or a modal dialog. */
export function isInTopLayer(element: Element | null | undefined): boolean {
  if (!element) return false
  try {
    return element.matches(':popover-open') || element.matches(':modal')
  } catch {
    return false
  }
}

/** Where an anchored element was placed, from its `data-side` and `data-align`. */
export interface AnchorPlacement {
  side: string | null
  align: string | null
}

/** Where an anchored element was placed (after any flip), from `data-side` and `data-align`. */
export function placementOf(element: Element): AnchorPlacement {
  return { side: element.getAttribute('data-side'), align: element.getAttribute('data-align') }
}

const FLAG = 'JOINERY_ANCHOR_FALLBACK'

/**
 * Forces the Floating UI fallback for each test in a module, as CI's fallback run does for the
 * whole suite, so one run covers both ways of positioning. It sets
 * `globalThis.JOINERY_ANCHOR_FALLBACK` before each test and puts it back after.
 *
 *   module('menu, Floating UI', function (hooks) {
 *     setupRenderingTest(hooks)
 *     setupAnchorFallback(hooks)
 *   })
 */
export function setupAnchorFallback(hooks: TestHooks): void {
  const global = globalThis as Record<string, unknown>
  let had = false
  let previous: unknown
  hooks.beforeEach(() => {
    had = FLAG in global
    previous = global[FLAG]
    global[FLAG] = true
  })
  hooks.afterEach(() => {
    if (had) global[FLAG] = previous
    else delete global[FLAG]
  })
}
