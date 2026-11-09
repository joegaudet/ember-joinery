/** Where a scroll is headed, as `scrollLeft` and `scrollTop` give it. An axis left out stays put. */
export interface ScrollTarget {
  left?: number
  top?: number
}

/** How many frames without movement count as the end of a scroll, where no `scrollend` comes. */
const STILL_FRAMES = 3

/**
 * How many, while a scroll is short of where it was headed: a busy page can drop a frame or two
 * of a smooth scroll, and one that stopped short (snapped elsewhere, or was taken over) gets its
 * `scrollend` anyway in browsers that have the event.
 */
const SHORT_STILL_FRAMES = 10

/**
 * How long a scroll that has somewhere to go may take to start moving, in milliseconds. A
 * smooth scroll can take a few frames to set off, more on a busy machine, and frames without
 * movement before then don't mean it ended.
 */
const START_TIMEOUT = 1000

/** The longest a scroll is waited for, so a page whose frames stop (a hidden tab) never hangs. */
const MAX_WAIT = 5000

/** Within a pixel: scroll positions can be fractional, and the sizes they're clamped to aren't. */
const near = (value: number, to: number | undefined) =>
  to === undefined || Math.abs(value - to) <= 1

/** Where a scroll to `target` comes to on `element`: the browser holds it within its range. */
function clamp(element: HTMLElement, target: ScrollTarget): ScrollTarget {
  const width = Math.max(0, element.scrollWidth - element.clientWidth)
  const height = Math.max(0, element.scrollHeight - element.clientHeight)
  // In right-to-left text `scrollLeft` runs from 0 at the right edge down to `-width`.
  const rtl = getComputedStyle(element).direction === 'rtl'
  const [min, max] = rtl ? [-width, 0] : [0, width]
  const goal: ScrollTarget = {}
  if (target.left !== undefined) goal.left = Math.min(max, Math.max(min, target.left))
  if (target.top !== undefined) goal.top = Math.min(height, Math.max(0, target.top))
  return goal
}

/**
 * Waits for a scroll of `element` to end: the `scrollend` event, or, where none comes (a scroll
 * that goes nowhere, a browser without the event), three frames in a row without movement.
 *
 * Given the `target` the scroll was sent to, a scroll that has somewhere to go is first waited
 * for to start: until it moves, gets there or ends, or a second has gone by. Only then do still
 * frames count, so a smooth scroll that is slow to set off isn't taken for one that ended.
 * Without a target, still frames count from the start.
 */
export function scrollEnd(element: HTMLElement, target?: ScrollTarget): Promise<void> {
  return new Promise(resolve => {
    const goal = target && clamp(element, target)
    const reached = () =>
      !goal || (near(element.scrollLeft, goal.left) && near(element.scrollTop, goal.top))
    const position = () => `${element.scrollLeft},${element.scrollTop}`
    const from = position()
    const began = performance.now()
    let started = reached()
    let done = false
    let last = from
    let still = 0
    const finish = () => {
      if (done) return
      done = true
      clearTimeout(timeout)
      element.removeEventListener('scrollend', finish)
      resolve()
    }
    const timeout = setTimeout(finish, MAX_WAIT)
    element.addEventListener('scrollend', finish)
    const check = () => {
      if (done) return
      if (!element.isConnected) return finish()
      const now = position()
      if (!started) {
        started = now !== from || reached() || performance.now() - began >= START_TIMEOUT
      } else if (now === last) {
        still += 1
      } else {
        still = 0
      }
      last = now
      if (started && still >= (reached() ? STILL_FRAMES : SHORT_STILL_FRAMES)) finish()
      else requestAnimationFrame(check)
    }
    requestAnimationFrame(check)
  })
}
