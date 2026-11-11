import { tracked } from '@glimmer/tracking'
import { waitForPromise } from '@ember/test-waiters'
import { modifier } from 'ember-modifier'

/** A sortable row's id: upstream's `UniqueIdentifier`, the row's `id`. */
export type SortableId = number | string

/**
 * What a screen reader is told about a drag handle, as dnd-kit's `DndContext` tells it
 * (its `defaultScreenReaderInstructions`), with Enter beside the space bar, which both start
 * and end a drag.
 */
export const SORTABLE_INSTRUCTIONS =
  'To pick up a draggable item, press the space bar or Enter. While dragging, use the arrow ' +
  'keys to move the item. Press the space bar or Enter again to drop the item in its new ' +
  'position, or press Escape to cancel.'

interface Measured {
  id: SortableId
  element: HTMLElement
  /** Its box in the viewport, where the pointer's coordinates are. */
  top: number
  height: number
  /** Its height in CSS pixels, which a transform moves it by (the page may be scaled). */
  size: number
}

interface Drag {
  id: SortableId
  by: 'pointer' | 'keyboard'
  items: Measured[]
  from: number
  over: number
  /** For a pointer drag: where it went down, and how far it has moved, in viewport pixels. */
  startY: number
  deltaY: number
  stop?: () => void
}

const TRANSITION = 'transform 250ms ease'

interface Registered {
  element: HTMLElement
}

/** Registers `element` under `id` until its modifier is torn down. */
function register(
  map: Map<SortableId, Registered>,
  id: SortableId,
  element: HTMLElement,
): () => void {
  const entry = { element }
  map.set(id, entry)
  return () => {
    if (map.get(id) === entry) map.delete(id)
  }
}

/**
 * Rows a user can reorder by dragging a handle, with a pointer or the keyboard: what
 * upstream's dashboard takes from dnd-kit (`DndContext` with `closestCenter` and
 * `restrictToVerticalAxis`, `SortableContext` with `verticalListSortingStrategy`, and
 * `useSortable` on each row and its handle). Joinery has no drag-and-drop package, so the block
 * carries this one; copy it with the block.
 *
 * Give each row `{{sortable.row id}}` and its handle `{{sortable.handle id}}`, and render
 * `announcement` in a live region and `SORTABLE_INSTRUCTIONS` under `instructionsId`. While a
 * row is dragged it follows the pointer up and down, the rows it passes make room for it, and
 * dropping it calls `onMove(activeId, overId)`, as upstream's `handleDragEnd` gets `active`
 * and `over`. A finger drags it as a mouse does (upstream's `TouchSensor`): the handle has
 * `touch-action: none`, so the browser doesn't take the touch for a scroll and cancel the drag,
 * and the handle keeps the pointer (`setPointerCapture`) until it lets go. From the keyboard,
 * Space or Enter picks the row up, the up and down arrows move it a row at a time (dnd-kit's
 * sortable keyboard coordinates; left and right do nothing, as they find no row beside it in a
 * column), Space, Enter or Tab drops it, and Escape puts it back. Each step is announced with
 * dnd-kit's own words.
 */
export class SortableRows {
  /** The row being dragged, while one is. */
  @tracked activeId: SortableId | null = null

  /** What the live region says: the last step of the last drag. */
  @tracked announcement = ''

  readonly instructionsId: string

  // By id, each with the install that put it there: Glimmer may install a modifier again on
  // the same element before it tears the old one down, which must then leave the new one.
  #rows = new Map<SortableId, Registered>()
  #handles = new Map<SortableId, Registered>()
  #drag: Drag | undefined
  #onMove: (activeId: SortableId, overId: SortableId) => void

  constructor({
    instructionsId,
    onMove,
  }: {
    instructionsId: string
    onMove: (activeId: SortableId, overId: SortableId) => void
  }) {
    this.instructionsId = instructionsId
    this.#onMove = onMove
  }

  /** `<t.Row {{sortable.row row.original.id}}>`: a row that moves while it is dragged. */
  row = modifier((element: HTMLElement, [id]: [SortableId]) => {
    element.setAttribute('data-dragging', 'false')
    return register(this.#rows, id, element)
  })

  /** `<Button {{sortable.handle row.original.id}}>`: the handle that drags its row. */
  handle = modifier((element: HTMLElement, [id]: [SortableId]) => {
    const unregister = register(this.#handles, id, element)
    element.setAttribute('aria-roledescription', 'sortable')
    element.setAttribute('aria-describedby', this.instructionsId)
    element.setAttribute('tabindex', '0')
    element.setAttribute('aria-disabled', 'false')
    // A touch on the handle drags, rather than scrolls the page: the browser would otherwise
    // take it for a pan and cancel the pointer (`pointercancel`), and the drag with it.
    const touchAction = element.style.touchAction
    element.style.touchAction = 'none'
    const onPointerDown = (event: PointerEvent) => {
      if (event.button !== 0 || this.#drag) return
      event.preventDefault()
      element.focus()
      this.#startPointer(id, event, element)
    }
    const onKeyDown = (event: KeyboardEvent) => this.#onKeyDown(id, event)
    element.addEventListener('pointerdown', onPointerDown)
    element.addEventListener('keydown', onKeyDown)
    return () => {
      element.removeEventListener('pointerdown', onPointerDown)
      element.removeEventListener('keydown', onKeyDown)
      element.style.touchAction = touchAction
      unregister()
    }
  })

  /** Whether `id`'s row is being dragged. */
  isDragging = (id: SortableId): boolean => this.activeId === id

  /** The rows on the page, top to bottom, measured where they are now. */
  #measure(): Measured[] {
    const rows = [...this.#rows.entries()]
      .map(([id, { element }]) => [id, element] as const)
      .filter(([, element]) => element.isConnected)
    rows.sort(([, a], [, b]) =>
      a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
    )
    return rows.map(([id, element]) => {
      const box = element.getBoundingClientRect()
      return { id, element, top: box.top, height: box.height, size: element.offsetHeight }
    })
  }

  #start(id: SortableId, by: Drag['by'], startY: number): Drag | undefined {
    const items = this.#measure()
    const from = items.findIndex(item => item.id === id)
    if (from === -1) return undefined
    const drag: Drag = { id, by, items, from, over: from, startY, deltaY: 0 }
    this.#drag = drag
    this.activeId = id
    this.#handles.get(id)?.element.setAttribute('aria-pressed', 'true')
    this.announcement = `Picked up draggable item ${id}.`
    this.#layout()
    return drag
  }

  #startPointer(id: SortableId, event: PointerEvent, handle: HTMLElement): void {
    const drag = this.#start(id, 'pointer', event.clientY)
    if (!drag) return
    // The handle keeps the pointer while it drags, wherever the finger or mouse goes. (A
    // pointer the browser doesn't know, such as a test's, can't be captured, and needn't be.)
    try {
      handle.setPointerCapture(event.pointerId)
    } catch {
      // Not a live pointer: its events still reach the document.
    }
    const doc = handle.ownerDocument
    const onMove = (move: PointerEvent) => {
      drag.deltaY = move.clientY - drag.startY
      // closestCenter: the row whose centre is nearest the dragged row's.
      const active = drag.items[drag.from]!
      const center = active.top + active.height / 2 + drag.deltaY
      let over = drag.from
      let nearest = Infinity
      drag.items.forEach((item, index) => {
        const distance = Math.abs(item.top + item.height / 2 - center)
        if (distance < nearest) {
          nearest = distance
          over = index
        }
      })
      this.#moveOver(over)
    }
    const onUp = () => this.#drop()
    const onCancel = () => this.#cancel()
    const onKey = (key: KeyboardEvent) => {
      if (key.key !== 'Escape') return
      key.preventDefault()
      this.#cancel()
    }
    doc.addEventListener('pointermove', onMove)
    doc.addEventListener('pointerup', onUp)
    doc.addEventListener('pointercancel', onCancel)
    doc.addEventListener('keydown', onKey, true)
    drag.stop = () => {
      doc.removeEventListener('pointermove', onMove)
      doc.removeEventListener('pointerup', onUp)
      doc.removeEventListener('pointercancel', onCancel)
      doc.removeEventListener('keydown', onKey, true)
    }
  }

  #onKeyDown(id: SortableId, event: KeyboardEvent): void {
    const drag = this.#drag
    if (!drag) {
      if (event.key !== ' ' && event.key !== 'Enter') return
      event.preventDefault()
      this.#start(id, 'keyboard', 0)
      return
    }
    if (drag.by !== 'keyboard' || drag.id !== id) return
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.#moveOver(Math.min(drag.items.length - 1, drag.over + 1))
        break
      case 'ArrowUp':
        event.preventDefault()
        this.#moveOver(Math.max(0, drag.over - 1))
        break
      // dnd-kit's sortable keyboard coordinates look for a row to the left or right of the
      // dragged one, and in a column there is none: the row stays, and the page doesn't scroll.
      case 'ArrowLeft':
      case 'ArrowRight':
        event.preventDefault()
        break
      case ' ':
      case 'Enter':
        event.preventDefault()
        this.#drop()
        break
      case 'Tab':
        this.#drop()
        break
      case 'Escape':
        event.preventDefault()
        this.#cancel()
        break
    }
  }

  #moveOver(over: number): void {
    const drag = this.#drag
    if (!drag) return
    if (over !== drag.over) {
      drag.over = over
      this.announcement = `Draggable item ${drag.id} was moved over droppable area ${drag.items[over]!.id}.`
    }
    this.#layout()
  }

  /** Moves each row where the drag puts it, as verticalListSortingStrategy does. */
  #layout(): void {
    const drag = this.#drag
    if (!drag) return
    const { items, from, over } = drag
    const active = items[from]!
    items.forEach((item, index) => {
      let y = 0
      if (index === from) {
        if (drag.by === 'pointer') {
          // Viewport pixels to CSS pixels, where the page is drawn scaled.
          y = active.height ? (drag.deltaY * active.size) / active.height : drag.deltaY
        } else if (over > from) {
          y = items.slice(from + 1, over + 1).reduce((sum, next) => sum + next.size, 0)
        } else if (over < from) {
          y = -items.slice(over, from).reduce((sum, next) => sum + next.size, 0)
        }
      } else if (from < index && index <= over) {
        y = -active.size
      } else if (over <= index && index < from) {
        y = active.size
      }
      item.element.style.transform = y ? `translate3d(0px, ${y}px, 0px)` : ''
      item.element.style.transition = index === from && drag.by === 'pointer' ? '' : TRANSITION
      item.element.setAttribute('data-dragging', String(index === from))
    })
  }

  #end(): Drag | undefined {
    const drag = this.#drag
    if (!drag) return undefined
    drag.stop?.()
    this.#drag = undefined
    this.activeId = null
    this.#handles.get(drag.id)?.element.removeAttribute('aria-pressed')
    for (const item of drag.items) {
      item.element.style.transform = ''
      item.element.style.transition = ''
      item.element.setAttribute('data-dragging', 'false')
    }
    return drag
  }

  #drop(): void {
    const drag = this.#end()
    if (!drag) return
    const overId = drag.items[drag.over]!.id
    this.announcement = `Draggable item ${drag.id} was dropped over droppable area ${overId}`
    if (overId !== drag.id) this.#onMove(drag.id, overId)
    this.#keepFocus(drag)
  }

  #cancel(): void {
    const drag = this.#end()
    if (!drag) return
    this.announcement = `Dragging was cancelled. Draggable item ${drag.id} was dropped.`
    this.#keepFocus(drag)
  }

  /**
   * The moved row's handle keeps focus. Rendering the row where it went moves its element,
   * which takes focus off it, and Ember renders as its run loop ends, so this looks once the
   * task after it runs (and tells the test waiters, so `settled()` waits for it).
   */
  #keepFocus(drag: Drag): void {
    const handle = this.#handles.get(drag.id)?.element
    if (!handle || handle.ownerDocument.activeElement !== handle) return
    void waitForPromise(
      new Promise<void>(resolve => setTimeout(resolve)).then(() => {
        const now = this.#handles.get(drag.id)?.element
        if (now && now.ownerDocument.activeElement !== now) now.focus()
      }),
    )
  }
}
