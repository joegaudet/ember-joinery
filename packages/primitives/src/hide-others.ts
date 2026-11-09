/** Puts back what `hideOthers` or `inertOthers` changed. */
export type Undo = () => void

export interface HideOthersOptions {
  /** Where to start: only what's inside it is hidden. Default the targets' `<body>`. */
  parent?: Element
}

type Targets = Element | ReadonlyArray<Element | null | undefined>

/** How many live calls hide each element, by the attribute they set. */
const counts: Record<string, WeakMap<Element, number>> = {}
/** Elements that had the attribute already, which are never given it back or taken off. */
const theirOwn: Record<string, WeakSet<Element>> = {}

function list(targets: Targets): Element[] {
  const all = Array.isArray(targets) ? targets : [targets as Element]
  return all.filter((target): target is Element => target instanceof Element)
}

/**
 * Sets `attribute` on every element in `parent` but the targets, their ancestors and the
 * elements it keeps, as the aria-hidden package does: it walks down from `parent`, and at each
 * level marks the children that hold no target. Calls stack, so an element stays marked until
 * every call that marked it is undone, and an element that had the attribute before keeps it.
 */
function applyToOthers(
  targets: Element[],
  parent: Element,
  attribute: string,
  marker: string,
): Undo {
  const keep = new Set<Element>()
  const stop = new Set(targets.filter(target => parent.contains(target)))
  for (const target of stop) {
    for (let node: Element | null = target; node && !keep.has(node); node = node.parentElement) {
      keep.add(node)
    }
  }
  const byAttribute = (counts[attribute] ??= new WeakMap())
  const own = (theirOwn[attribute] ??= new WeakSet())
  const marked: Element[] = []

  const walk = (node: Element) => {
    if (stop.has(node)) return
    for (const child of node.children) {
      if (keep.has(child)) {
        walk(child)
        continue
      }
      const count = byAttribute.get(child) ?? 0
      if (count === 0) {
        const value = child.getAttribute(attribute)
        // `inert` is a boolean attribute: any value is inert. `aria-hidden="false"` isn't hidden.
        const already = attribute === 'inert' ? value !== null : value !== null && value !== 'false'
        if (already) own.add(child)
        else child.setAttribute(attribute, attribute === 'inert' ? '' : 'true')
        child.setAttribute(marker, 'true')
      }
      byAttribute.set(child, count + 1)
      marked.push(child)
    }
  }
  walk(parent)

  let undone = false
  return () => {
    if (undone) return
    undone = true
    for (const node of marked) {
      const count = (byAttribute.get(node) ?? 1) - 1
      byAttribute.set(node, count)
      if (count > 0) continue
      if (own.has(node)) own.delete(node)
      else node.removeAttribute(attribute)
      node.removeAttribute(marker)
    }
  }
}

function start(targets: Targets, options: HideOthersOptions): [Element[], Element] | undefined {
  const elements = list(targets)
  const parent = options.parent ?? elements[0]?.ownerDocument.body
  if (!parent) return undefined
  // Live regions and scripts stay as they are: an announcement outside a dialog is still heard.
  elements.push(...parent.querySelectorAll('[aria-live], script'))
  return [elements, parent]
}

/**
 * Hides everything on the page from assistive technology but the targets, as the aria-hidden
 * package's `hideOthers` (which Radix's modal parts use) does: `aria-hidden="true"` on every
 * element that isn't a target, inside one or above one. Live regions (`aria-live`) stay heard.
 * It returns the function that puts it all back; calls stack, so an element stays hidden until
 * every call that hid it is undone, and one that was hidden already stays hidden.
 *
 *   const undo = hideOthers(dialog)
 *   undo()
 *
 * Hidden elements can still take focus, so trap it inside the targets (`focusScope`), or use
 * `inertOthers`, which a modal dialog does.
 */
export function hideOthers(targets: Targets, options: HideOthersOptions = {}): Undo {
  const started = start(targets, options)
  if (!started) return () => {}
  return applyToOthers(started[0], started[1], 'aria-hidden', 'data-aria-hidden')
}

/**
 * Makes everything on the page inert but the targets, as a modal `<dialog>` does to the page
 * behind it (and as the aria-hidden package's `inertOthers`): `inert` on every element that isn't
 * a target, inside one or above one, so nothing else can be focused, clicked or read by
 * assistive technology. Live regions (`aria-live`) are left alone, so a toast outside stays
 * heard and usable. It returns the function that puts it all back; calls stack, as
 * `hideOthers`' do.
 *
 *   const undo = inertOthers([dialog, overlay])
 *   undo()
 */
export function inertOthers(targets: Targets, options: HideOthersOptions = {}): Undo {
  const started = start(targets, options)
  if (!started) return () => {}
  return applyToOthers(started[0], started[1], 'inert', 'data-inert-ed')
}
