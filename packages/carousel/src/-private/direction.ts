/** Callbacks to call when any element's `dir` changes. */
const listeners = new Set<() => void>()

let observer: MutationObserver | undefined

/**
 * Calls `callback` whenever a `dir` attribute changes anywhere in the document, as the guide's
 * RTL switch or an app's language picker does, until the returned function is called. One
 * observer serves every carousel, and it watches only while one is listening.
 */
export function watchDirection(callback: () => void): () => void {
  if (typeof MutationObserver === 'undefined') return () => {}
  if (!listeners.size) {
    observer ??= new MutationObserver(() => {
      for (const listener of [...listeners]) listener()
    })
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['dir'],
      subtree: true,
    })
  }
  listeners.add(callback)
  return () => {
    listeners.delete(callback)
    if (!listeners.size) observer?.disconnect()
  }
}
