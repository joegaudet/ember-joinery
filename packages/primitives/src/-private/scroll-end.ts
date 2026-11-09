/** How many frames without movement count as the end of a scroll, where no `scrollend` comes. */
const STILL_FRAMES = 3

/**
 * Waits for a scroll to end: the `scrollend` event, or, where none comes (a scroll that goes
 * nowhere, a browser without the event), three frames in a row without movement.
 */
export function scrollEnd(element: HTMLElement): Promise<void> {
  return new Promise(resolve => {
    const position = () => `${element.scrollLeft},${element.scrollTop}`
    let done = false
    let last = position()
    let still = 0
    const finish = () => {
      if (done) return
      done = true
      element.removeEventListener('scrollend', finish)
      resolve()
    }
    element.addEventListener('scrollend', finish)
    const check = () => {
      if (done) return
      const now = position()
      if (now === last) {
        still += 1
      } else {
        still = 0
        last = now
      }
      if (still >= STILL_FRAMES || !element.isConnected) finish()
      else requestAnimationFrame(check)
    }
    requestAnimationFrame(check)
  })
}
