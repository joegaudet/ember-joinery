import { doubleClick, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey, type KeyModifiers } from './focus.ts'
import { sendPointer } from './send-pointer.ts'

/** Which handle: its index among the group's handles, counting from 0. */
type HandleIndex = number

/** Which panel: its index, counting from 0, or its `@id`. */
type PanelKey = number | string

/** How far to drag a handle: pixels along the group's axis, or `{ x, y }`. */
export type DragDistance = number | { x?: number; y?: number }

/**
 * Drives a resizable group: `<Resizable>` from `@ember-joinery/primitives/resizable`, or
 * `<ResizablePanelGroup>` from `@ember-joinery/ember`. Panels and handles are its parts. Sizes
 * are read from the layout as rendered, and each handle's state from its ARIA (`aria-valuenow`
 * is the size of the panel before it). Panels of a group nested in a panel belong to that
 * group, which has a harness of its own.
 *
 *   const layout = new ResizableHarness('workspace')
 *   await layout.drag(0, 40)                // the first handle, 40px right (or down)
 *   await layout.press(0, 'ArrowLeft')
 *   assert.deepEqual(layout.sizes, [45, 55])
 */
export class ResizableHarness extends Harness {
  static override component = 'resizable'

  /** `horizontal` (panels side by side) or `vertical` (stacked). */
  get orientation(): 'horizontal' | 'vertical' {
    return this.element.getAttribute('data-orientation') === 'vertical' ? 'vertical' : 'horizontal'
  }

  /** The panels, in order. */
  get panels(): HTMLElement[] {
    return this.parts('panel')
  }

  /** The handles, in order. */
  get handles(): HTMLElement[] {
    return this.parts('handle')
  }

  /** A panel, by its index or its `@id`. Throws when there is none. */
  panel(key: PanelKey): HTMLElement {
    if (typeof key === 'string') return this.part('panel', key)
    const panel = this.panels[key]
    if (!panel) throw new Error(`no panel #${key} in ${this}`)
    return panel
  }

  /** A handle, by its index. Throws when there is none. */
  handle(index: HandleIndex = 0): HTMLElement {
    const handle = this.handles[index]
    if (!handle) throw new Error(`no handle #${index} in ${this}`)
    return handle
  }

  /**
   * Each panel's share of the space the panels take, in percent, as rendered, to one decimal
   * place. They add up to about 100.
   */
  get sizes(): number[] {
    const horizontal = this.orientation === 'horizontal'
    const lengths = this.panels.map(panel => {
      const box = panel.getBoundingClientRect()
      return horizontal ? box.width : box.height
    })
    const total = lengths.reduce((sum, length) => sum + length, 0)
    return lengths.map(length => (total > 0 ? Math.round((length / total) * 1000) / 10 : 0))
  }

  /** One panel's size, as `sizes` gives it. */
  size(key: PanelKey): number {
    const index = typeof key === 'number' ? key : this.panels.indexOf(this.panel(key))
    return this.sizes[index]!
  }

  /** A handle's `aria-valuenow`: the size of the panel before it, in percent. */
  valueNow(index: HandleIndex = 0): number {
    return Number(this.handle(index).getAttribute('aria-valuenow'))
  }

  /** A handle's `aria-valuemin` and `aria-valuemax`: how small and large it can make its panel. */
  range(index: HandleIndex = 0): { min: number; max: number } {
    const handle = this.handle(index)
    return {
      min: Number(handle.getAttribute('aria-valuemin')),
      max: Number(handle.getAttribute('aria-valuemax')),
    }
  }

  /** The panel a handle resizes (`aria-controls`): the one before it. */
  controls(index: HandleIndex = 0): HTMLElement | null {
    const id = this.handle(index).getAttribute('aria-controls')
    return id ? this.element.ownerDocument.getElementById(id) : null
  }

  /** A handle's state: `inactive`, `hover`, `focus`, `active` (dragging) or `disabled`. */
  handleState(index: HandleIndex = 0): string | null {
    return this.handle(index).getAttribute('data-separator')
  }

  /** Whether a handle can't be moved (`aria-disabled`). */
  isHandleDisabled(index: HandleIndex = 0): boolean {
    return this.handle(index).getAttribute('aria-disabled') === 'true'
  }

  /** Whether a collapsible panel is collapsed (`data-collapsed`). */
  isCollapsed(key: PanelKey): boolean {
    return this.panel(key).hasAttribute('data-collapsed')
  }

  /** Moves focus to a handle, as tabbing to it would. */
  async focus(index: HandleIndex = 0): Promise<void> {
    await focus(this.handle(index))
  }

  /** Focuses a handle and presses a key on it: an arrow key, `Home`, `End`, `Enter` or `F6`. */
  async press(index: HandleIndex, key: string, modifiers: KeyModifiers = {}): Promise<boolean> {
    await this.focus(index)
    return pressKey(key, modifiers)
  }

  /** Puts the pointer over a handle, and (with `false`) takes it away. */
  async hover(index: HandleIndex = 0, over = true): Promise<void> {
    await sendPointer(this.handle(index), over ? 'pointerenter' : 'pointerleave')
  }

  /** Double-clicks a handle, which puts its panel back to its `@defaultSize`. */
  async doubleClick(index: HandleIndex = 0): Promise<void> {
    await doubleClick(this.handle(index))
  }

  /**
   * Drags a handle with the primary pointer: down on its middle, moved `distance` (CSS pixels
   * along the axis, or `{ x, y }`) in `steps` moves, then up. Right and down are positive,
   * whatever the text direction.
   */
  async drag(index: HandleIndex, distance: DragDistance, { steps = 4 } = {}): Promise<void> {
    const handle = this.handle(index)
    const box = handle.getBoundingClientRect()
    const x0 = box.left + box.width / 2
    const y0 = box.top + box.height / 2
    const { x = 0, y = 0 } =
      typeof distance === 'number'
        ? this.orientation === 'horizontal'
          ? { x: distance }
          : { y: distance }
        : distance
    // The distance is in the page's CSS pixels; the pointer's are the screen's, which a
    // transform (the test container's scale) makes differ.
    const group = this.element
    const scale = group.offsetWidth ? group.getBoundingClientRect().width / group.offsetWidth : 1
    const at = (dx: number, dy: number) => ({ clientX: x0 + dx * scale, clientY: y0 + dy * scale })
    await sendPointer(handle, 'pointerdown', at(0, 0))
    for (let step = 1; step <= steps; step++) {
      await sendPointer(handle, 'pointermove', at((x * step) / steps, (y * step) / steps))
    }
    await sendPointer(handle, 'pointerup', { ...at(x, y), buttons: 0 })
  }
}
