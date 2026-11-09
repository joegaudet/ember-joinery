import { register, type TestWaiterDebugInfo, type Waiter } from '@ember/test-waiters'
import type { EmblaCarouselType } from 'embla-carousel'

/** Every carousel on the page, while it lives. */
const live = new Set<EmblaCarouselType>()

/** Work put off past the current render, which `settled()` waits for. */
let deferred = 0

/** How close (in pixels, and pixels a step) a carousel must be to its target to be at rest. */
const REST = 0.5

/**
 * Whether a carousel has come to rest where a user sees it: not being dragged, and within half
 * a pixel of where it is going, barely moving. Embla's own `settle` comes a good while later,
 * once its easing is within a thousandth of a pixel (and not always after a jump), so tests
 * would wait for nothing anyone can see.
 */
function isAtRest(api: EmblaCarouselType): boolean {
  const engine = api.internalEngine()
  if (engine.dragHandler.pointerDown()) return false
  const distance = Math.abs(engine.target.get() - engine.location.get())
  return distance < REST && Math.abs(engine.scrollBody.velocity()) < REST
}

/**
 * One test waiter for every carousel: `settled()` (and so every `@ember/test-helpers` action)
 * waits while one is scrolling to a slide or being dragged, and for the state a carousel puts
 * off past rendering. So a test reads the slides where they come to rest. Outside tests it
 * costs one entry in the waiters' map.
 */
const waiter: Waiter = {
  name: '@ember-joinery/carousel',
  waitUntil: () => deferred === 0 && [...live].every(isAtRest),
  debugInfo: (): TestWaiterDebugInfo[] => [
    ...(deferred
      ? [{ label: `${deferred} carousel update(s) put off past rendering`, stack: undefined }]
      : []),
    ...[...live]
      .filter(api => !isAtRest(api))
      .map(() => ({ label: 'a carousel still moving', stack: undefined })),
  ],
}

let registered = false

/** Counts a carousel in, for the waiter, until `untrack`. */
export function track(api: EmblaCarouselType): void {
  if (!registered) {
    register(waiter)
    registered = true
  }
  live.add(api)
}

/** Counts a carousel out. */
export function untrack(api: EmblaCarouselType): void {
  live.delete(api)
}

/**
 * Runs `callback` once the current render is done (in a microtask), for work that sets tracked
 * state: a modifier, or an Embla event fired while the carousel reinitializes during a render,
 * mustn't set state the render has read. The waiter waits for it.
 */
export function defer(callback: () => void): void {
  deferred += 1
  void Promise.resolve()
    .then(callback)
    .finally(() => {
      deferred -= 1
    })
}
