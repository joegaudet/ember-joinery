import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import Modifier from 'ember-modifier'
import { getDirection, type Direction } from '../direction.gts'
import { idFor } from '../id.ts'
import { ignoreROError } from '../resize-observer.ts'
import {
  adjustLayout,
  defaultLayout,
  handleRange,
  isAbsolute,
  round,
  same,
  sameLayout,
  toPercent,
  validateLayout,
  type PanelConstraints,
  type PanelSize,
  type ResizeTrigger,
} from './layout.ts'

/** Which way the panels run: side by side (`horizontal`), or stacked (`vertical`). */
export type ResizableOrientation = 'horizontal' | 'vertical'

/** A layout by panel id, as react-resizable-panels' `Layout` is: `{ sidebar: 25, main: 75 }`. */
export type ResizableLayoutMap = Record<string, number>

/** A panel's size: in percent of the group, and in pixels. */
export interface ResizablePanelSize {
  asPercentage: number
  inPixels: number
}

/** What `@onLayoutChanged` is told about a change. */
export interface ResizableLayoutMeta {
  /** Whether a pointer or a key made it, rather than the first layout or a call. */
  isUserInteraction: boolean
}

/** What a resizable group takes. Each is a function, so the group reads it live. */
export interface ResizableGroupOptions {
  /** Default `horizontal`. */
  orientation?: () => ResizableOrientation | undefined
  /** The text direction, when the document's shouldn't decide. */
  dir?: () => Direction | undefined
  /** Whether nothing in the group can be resized. */
  disabled?: () => boolean | undefined
  /** Whether to leave the cursor alone (no resize cursor over a handle, or while dragging). */
  disableCursor?: () => boolean | undefined
  /** The first layout, in percent: one size per panel in order, or sizes by panel `@id`. */
  defaultLayout?: () => readonly number[] | ResizableLayoutMap | undefined
  /** Called while the layout changes (on every pointer move), with the sizes in order and by id. */
  onLayoutChange?: () => ((sizes: number[], layout: ResizableLayoutMap) => void) | undefined
  /** Called once a change is over (when the pointer is released), with the sizes as above. */
  onLayoutChanged?: () =>
    ((sizes: number[], layout: ResizableLayoutMap, meta: ResizableLayoutMeta) => void) | undefined
}

/** What a panel takes, as `<ResizablePanel>` or the `panel` modifier. */
export interface ResizablePanelOptions {
  /** Its id: the key of its size in a layout, and its element's `id`. Default: one made for it. */
  id?: string
  /**
   * Its first size. A string is a percentage (`"50%"`, or `"50"`) unless it has a unit (`"200px"`,
   * `"10rem"`, `"2em"`, `"50vh"`, `"50vw"`); a number is pixels. Without one, the panels that
   * don't ask for a size share what is left.
   */
  defaultSize?: PanelSize
  /** The smallest it can be, as `defaultSize`. Default `0%`. */
  minSize?: PanelSize
  /** The largest it can be, as `defaultSize`. Default `100%`. */
  maxSize?: PanelSize
  /** Whether it collapses when resized below its minimum. */
  collapsible?: boolean
  /** Its size when collapsed, as `defaultSize`. Default `0%`. */
  collapsedSize?: PanelSize
  /**
   * How far past its minimum it must go to collapse, or past its collapsed size to expand.
   * Default: half the distance between the two.
   */
  collapsedThreshold?: PanelSize
  /** Whether it can't be resized, by its own handles or by another panel's. */
  disabled?: boolean
  /**
   * When the group changes size: keep its share (`preserve-relative-size`, the default) or its
   * size in pixels (`preserve-pixel-size`). A group needs at least one panel that keeps its share.
   */
  groupResizeBehavior?: 'preserve-relative-size' | 'preserve-pixel-size'
  /** Called when its size changes, with the size before (none the first time). */
  onResize?: (
    size: ResizablePanelSize,
    id: string,
    previous: ResizablePanelSize | undefined,
  ) => void
  /** @internal The panel's API to bind, from `<ResizablePanel>`. */
  api?: ResizablePanelApi
}

/** What a handle takes, as `<ResizableHandle>` or the `handle` modifier. */
export interface ResizableHandleOptions {
  /** Whether it can't be moved. Its panels can still change size through other handles. */
  disabled?: boolean
  /** Whether double-clicking it leaves its panel's size alone, instead of restoring its default. */
  disableDoubleClick?: boolean
}

/** A handle's state, as `data-separator` (react-resizable-panels' attribute) shows it. */
export type ResizableHandleState = 'inactive' | 'hover' | 'focus' | 'active' | 'disabled'

interface PanelMember {
  readonly kind: 'panel'
  readonly element: HTMLElement
  options: ResizablePanelOptions
  /** The size it had before it last collapsed, to expand back to. */
  expandedSize?: number
  /** The size `onResize` was last told. */
  reported?: ResizablePanelSize
}

interface HandleMember {
  readonly kind: 'handle'
  readonly element: HTMLElement
  options: ResizableHandleOptions
  hovered: boolean
  focused: boolean
  /** Stops its listeners, once it listens. */
  unlisten?: () => void
}

type Member = PanelMember | HandleMember

interface Drag {
  handle: HandleMember
  pointerId: number
  start: number
  /** The panels' total size in pixels when the drag started. */
  axis: number
  initial: readonly number[]
  pivot: readonly [number, number]
  constraints: readonly PanelConstraints[]
  done: () => void
}

const waiter = buildWaiter('@ember-joinery/primitives:resizable')

/** How far an arrow key moves a handle, in percent; Shift moves it further. */
const KEYBOARD_STEP = 5
const KEYBOARD_STEP_SHIFT = 10

function set(element: HTMLElement, name: string, value: string | null): void {
  if (value === null) element.removeAttribute(name)
  else if (element.getAttribute(name) !== value) element.setAttribute(name, value)
}

function style(element: HTMLElement, property: string, value: string | null): void {
  if (value === null) element.style.removeProperty(property)
  else if (element.style.getPropertyValue(property) !== value)
    element.style.setProperty(property, value)
}

/** A number for an ARIA value: three decimals at most, as react-resizable-panels gives. */
function ariaNumber(value: number): string {
  return String(round(value))
}

/** One style sheet for the resize cursor while a drag is on, adopted by the document. */
let cursorSheet: CSSStyleSheet | undefined

function showCursor(document: Document, cursor: string | null): void {
  if (!('adoptedStyleSheets' in document)) return
  cursorSheet ??= new CSSStyleSheet()
  const sheets = document.adoptedStyleSheets.filter(sheet => sheet !== cursorSheet)
  if (cursor === null) {
    document.adoptedStyleSheets = sheets
    return
  }
  cursorSheet.replaceSync(
    `*, *:hover { cursor: ${cursor} !important; user-select: none !important; -webkit-user-select: none !important; }`,
  )
  document.adoptedStyleSheets = [...sheets, cursorSheet]
}

/**
 * The engine of a resizable group, as react-resizable-panels' `Group` (and ember-primitives'
 * `Resizable`): panels side by side or stacked, sized in percent of the space they share, with
 * a handle between each two that a pointer drags and the keyboard moves, as in APG's window
 * splitter pattern.
 *
 * A component makes one and puts its modifiers on its elements: `group` on the group's,
 * `panel` on each panel's and `handle` on each handle's. Panels and handles are the group
 * element's children, in order: the handle between two panels resizes them. The group writes
 * the panels' sizes into their style (`flex-grow`, so the handles keep their own size), and the
 * handles' ARIA (`aria-valuenow` is the size of the panel before it, which it `aria-controls`).
 *
 *   class Layout extends Component {
 *     group = new ResizableGroup({ orientation: () => this.args.orientation })
 *     <template>
 *       <div {{this.group.group}}>
 *         <div {{this.group.panel defaultSize="30%" minSize="20%"}}>…</div>
 *         <div {{this.group.handle}} aria-label="Resize the sidebar"></div>
 *         <div {{this.group.panel}}>…</div>
 *       </div>
 *     </template>
 *   }
 */
export class ResizableGroup {
  readonly #options: ResizableGroupOptions
  #element: HTMLElement | null = null
  #members: Member[] = []
  /** Each panel's size now, in percent. */
  #sizes = new Map<PanelMember, number>()
  #scheduled = false
  #laidOut = false
  #destroyed = false
  #drag: Drag | null = null
  /** The panels' total size in pixels at the last layout. */
  #axis = 0
  #observer: ResizeObserver | undefined

  /** The sizes, in order, as last laid out. */
  @tracked private snapshot: { panels: readonly PanelMember[]; sizes: readonly number[] } = {
    panels: [],
    sizes: [],
  }

  constructor(options: ResizableGroupOptions = {}) {
    this.#options = options
  }

  /** `horizontal` or `vertical`. */
  get orientation(): ResizableOrientation {
    return this.#options.orientation?.() ?? 'horizontal'
  }

  get #horizontal(): boolean {
    return this.orientation === 'horizontal'
  }

  /** Whether the group can't be resized. */
  get disabled(): boolean {
    return Boolean(this.#options.disabled?.())
  }

  /** The panels' sizes in percent, in order. Tracked. */
  get layout(): readonly number[] {
    return this.snapshot.sizes
  }

  /** The panels' sizes by id, as react-resizable-panels' `getLayout()`. */
  getLayout = (): ResizableLayoutMap => {
    const { panels, sizes } = this.snapshot
    return Object.fromEntries(panels.map((panel, index) => [this.#idOf(panel), sizes[index]!]))
  }

  /**
   * Sets the sizes (in percent): one per panel in order, or by panel id. Constraints still
   * apply, so the layout may differ; it returns the layout it set.
   */
  setLayout = (layout: readonly number[] | ResizableLayoutMap): ResizableLayoutMap => {
    const panels = this.#panels()
    const requested = this.#fromLayout(layout, panels)
    if (requested) {
      const next = validateLayout(requested, this.#constraints(panels))
      this.#commit(panels, next, { complete: true, user: false })
    }
    return this.getLayout()
  }

  /** The size of `panel` in percent, or `undefined` before the group lays it out. Tracked. */
  sizeOf(panel: PanelMember): number | undefined {
    const { panels, sizes } = this.snapshot
    const index = panels.indexOf(panel)
    return index === -1 ? undefined : sizes[index]
  }

  // ----- Modifiers ---------------------------------------------------------------------------

  /** The group's element. Takes the arguments it reacts to, so it updates when they change. */
  group: typeof Modifier<{
    Element: HTMLElement
    Args: { Named: { orientation?: ResizableOrientation; disabled?: boolean } }
  }> = groupModifier(this)

  /** A panel: `<div {{group.panel defaultSize="30%"}}>`. */
  panel: typeof Modifier<{ Element: HTMLElement; Args: { Named: ResizablePanelOptions } }> =
    panelModifier(this)

  /** A handle between two panels: `<div {{group.handle}}>`. */
  handle: typeof Modifier<{ Element: HTMLElement; Args: { Named: ResizableHandleOptions } }> =
    handleModifier(this)

  // ----- Members -----------------------------------------------------------------------------

  /** @internal */
  attach(element: HTMLElement): () => void {
    this.#element = element
    this.#destroyed = false
    ignoreROError()
    this.#observer = new ResizeObserver(() => this.#onResize())
    this.#observer.observe(element)
    this.changed()
    return () => {
      this.#observer?.disconnect()
      this.#observer = undefined
      this.#endDrag()
      this.#element = null
      this.#destroyed = true
    }
  }

  /** @internal */
  register(member: Member): () => void {
    this.#members.push(member)
    if (member.kind === 'handle') this.#listen(member)
    this.changed()
    return () => {
      this.#members = this.#members.filter(other => other !== member)
      if (member.kind === 'panel') {
        this.#sizes.delete(member)
        member.options.api?.unbind(member)
      }
      if (this.#drag && (this.#drag.handle === member || member.kind === 'panel')) this.#endDrag()
      this.changed()
    }
  }

  /** @internal Something changed that the layout depends on: lay it out again after the render. */
  changed(): void {
    if (this.#scheduled || this.#destroyed) return
    this.#scheduled = true
    // After the render that brought the change, so every member has come, and before the
    // browser paints. The layout writes tracked state, which the render can't.
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      waiter.endAsync(token)
      this.#flush()
    })
  }

  /** The panels in document order (they are the group's children). */
  #panels(): PanelMember[] {
    return this.#ordered().filter((member): member is PanelMember => member.kind === 'panel')
  }

  #handles(): HandleMember[] {
    return this.#ordered().filter((member): member is HandleMember => member.kind === 'handle')
  }

  #ordered(): Member[] {
    return [...this.#members].sort((a, b) =>
      a.element.compareDocumentPosition(b.element) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
    )
  }

  /** A panel's id: its `@id`, or its element's (one the group gives it, if it has none). */
  #idOf(panel: PanelMember): string {
    return panel.options.id ?? (panel.element.id || idFor(panel, 'panel'))
  }

  /** The panels either side of a handle, as indices in `panels`. */
  #pivot(handle: HandleMember, panels: readonly PanelMember[]): [number, number] | undefined {
    let before = -1
    panels.forEach((panel, index) => {
      if (panel.element.compareDocumentPosition(handle.element) & Node.DOCUMENT_POSITION_FOLLOWING)
        before = index
    })
    if (before === -1 || before === panels.length - 1) return undefined
    return [before, before + 1]
  }

  // ----- Measuring ---------------------------------------------------------------------------

  /** The space the panels share, in pixels: the group's, less the handles'. */
  #measure(): number {
    const element = this.#element
    if (!element) return 0
    const computed = getComputedStyle(element)
    const horizontal = this.#horizontal
    let size = horizontal
      ? element.clientWidth - parseFloat(computed.paddingLeft) - parseFloat(computed.paddingRight)
      : element.clientHeight - parseFloat(computed.paddingTop) - parseFloat(computed.paddingBottom)
    for (const handle of this.#handles()) {
      const box = handle.element.getBoundingClientRect()
      const own = getComputedStyle(handle.element)
      size -= horizontal
        ? box.width + parseFloat(own.marginLeft) + parseFloat(own.marginRight)
        : box.height + parseFloat(own.marginTop) + parseFloat(own.marginBottom)
    }
    return Math.max(0, size)
  }

  #constraints(panels: readonly PanelMember[], axis = this.#axis): PanelConstraints[] {
    return panels.map(({ element, options }) => {
      const percent = (size: PanelSize | undefined, fallback: number) =>
        size === undefined ? fallback : toPercent(size, axis, element)
      // Without a size, a group can't turn pixels into percent: only percentages hold.
      const usable = (size: PanelSize | undefined) =>
        axis > 0 || !isAbsolute(size) ? size : undefined
      return {
        minSize: percent(usable(options.minSize), 0),
        maxSize: percent(usable(options.maxSize), 100),
        collapsible: Boolean(options.collapsible),
        collapsedSize: percent(usable(options.collapsedSize), 0),
        collapsedThreshold:
          usable(options.collapsedThreshold) === undefined
            ? undefined
            : percent(options.collapsedThreshold, 0),
        defaultSize:
          usable(options.defaultSize) === undefined ? undefined : percent(options.defaultSize, 0),
        disabled: Boolean(options.disabled),
      }
    })
  }

  /** A layout from `@defaultLayout` or `setLayout()`, if it names every panel. */
  #fromLayout(
    layout: readonly number[] | ResizableLayoutMap | undefined,
    panels: readonly PanelMember[],
  ): number[] | undefined {
    if (!layout) return undefined
    if (Array.isArray(layout)) {
      return layout.length === panels.length ? [...(layout as number[])] : undefined
    }
    const map = layout as ResizableLayoutMap
    const sizes = panels.map(panel => map[this.#idOf(panel)])
    return sizes.every(size => typeof size === 'number') ? (sizes as number[]) : undefined
  }

  // ----- Layout ------------------------------------------------------------------------------

  /** Lays the group out after members came or went, or their constraints changed. */
  #flush(): void {
    this.#scheduled = false
    const element = this.#element
    if (!element || this.#destroyed) return

    this.#styleGroup(element)
    const panels = this.#panels()
    // The panels share the space by flex-grow, from a flex-basis of 0: set that before measuring.
    for (const panel of panels) this.#stylePanel(panel)
    for (const handle of this.#handles()) this.#styleHandle(handle)
    if (panels.length === 0) {
      this.#commit(panels, [], { complete: true, user: false })
      return
    }
    this.#axis = this.#measure()
    const constraints = this.#constraints(panels)

    let layout: number[] | undefined
    if (!this.#laidOut) layout = this.#fromLayout(this.#options.defaultLayout?.(), panels)
    if (!layout) {
      const known = panels.filter(panel => this.#sizes.has(panel))
      if (known.length === 0) {
        layout = defaultLayout(constraints)
      } else {
        // Panels that were there keep their size; new ones take theirs, or share what is left,
        // or, with nothing left, take an equal share as the others make room (as a new window
        // opens in a tiling window manager).
        const sizes = panels.map(panel => this.#sizes.get(panel))
        const fresh = sizes.flatMap((size, index) => (size === undefined ? [index] : []))
        const asked = fresh.filter(index => constraints[index]!.defaultSize !== undefined)
        const unasked = fresh.filter(index => constraints[index]!.defaultSize === undefined)
        const taken =
          sizes.reduce<number>((sum, size) => sum + (size ?? 0), 0) +
          asked.reduce((sum, index) => sum + constraints[index]!.defaultSize!, 0)
        let share = unasked.length ? (100 - taken) / unasked.length : 0
        if (unasked.length && share < 1) share = 100 / panels.length
        layout = sizes.map((size, index) => size ?? constraints[index]!.defaultSize ?? share)
      }
    }
    const next = validateLayout(layout, constraints)
    const first = !this.#laidOut
    this.#laidOut = true
    this.#commit(panels, next, { complete: true, user: false, force: first })
  }

  /** The group changed size: panels sized in pixels keep their size, and constraints convert. */
  #onResize(): void {
    if (!this.#laidOut || this.#drag || !this.#element) return
    const panels = this.#panels()
    if (!panels.length) return
    const previousAxis = this.#axis
    const axis = this.#measure()
    if (same(axis, previousAxis, 0.5)) return
    const absolute = panels.some(
      ({ options }) =>
        options.groupResizeBehavior === 'preserve-pixel-size' ||
        [
          options.defaultSize,
          options.minSize,
          options.maxSize,
          options.collapsedSize,
          options.collapsedThreshold,
        ].some(isAbsolute),
    )
    this.#axis = axis
    if (!absolute) return
    let layout = panels.map(panel => this.#sizes.get(panel) ?? 0)
    const fixed = panels.map(
      panel => panel.options.groupResizeBehavior === 'preserve-pixel-size' && previousAxis > 0,
    )
    if (fixed.some(Boolean) && axis > 0) {
      const kept = layout.map((size, index) =>
        fixed[index] ? (size / 100) * (previousAxis / axis) * 100 : size,
      )
      const fixedTotal = kept.reduce((sum, size, index) => (fixed[index] ? sum + size : sum), 0)
      const relativeTotal = kept.reduce((sum, size, index) => (fixed[index] ? sum : sum + size), 0)
      const scale = relativeTotal > 0 ? Math.max(0, 100 - fixedTotal) / relativeTotal : 0
      layout = kept.map((size, index) => (fixed[index] ? size : size * scale))
    }
    this.#commit(panels, validateLayout(layout, this.#constraints(panels, axis)), {
      complete: true,
      user: false,
    })
  }

  /** Writes a layout: the panels' sizes, the handles' ARIA, and tells whoever listens. */
  #commit(
    panels: readonly PanelMember[],
    layout: readonly number[],
    { complete, user, force = false }: { complete: boolean; user: boolean; force?: boolean },
  ): void {
    const before = panels.map(panel => this.#sizes.get(panel))
    panels.forEach((panel, index) => this.#sizes.set(panel, layout[index]!))
    const changed =
      force || before.some((size, index) => size === undefined || !same(size, layout[index]!))

    const constraints = this.#constraints(panels)
    panels.forEach((panel, index) => {
      const size = layout[index]!
      style(panel.element, 'flex-grow', String(size))
      const c = constraints[index]!
      const collapsed = c.collapsible && same(size, c.collapsedSize)
      set(panel.element, 'data-collapsed', collapsed ? '' : null)
      panel.options.api?.bind(this, panel)
    })
    this.#syncHandles(panels, layout, constraints)

    if (!sameLayout(this.snapshot.sizes, layout) || this.snapshot.panels.length !== panels.length)
      this.snapshot = { panels: [...panels], sizes: [...layout] }
    else if (this.snapshot.panels.some((panel, index) => panel !== panels[index]))
      this.snapshot = { panels: [...panels], sizes: [...layout] }

    if (!changed) return
    const sizes = [...layout]
    const map = this.getLayout()
    this.#options.onLayoutChange?.()?.(sizes, map)
    panels.forEach((panel, index) => {
      const size = {
        asPercentage: layout[index]!,
        inPixels: round((layout[index]! / 100) * this.#axis),
      }
      const reported = panel.reported
      if (reported && same(reported.asPercentage, size.asPercentage)) return
      panel.reported = size
      panel.options.onResize?.(size, this.#idOf(panel), reported)
    })
    if (complete) this.#options.onLayoutChanged?.()?.(sizes, map, { isUserInteraction: user })
  }

  #syncHandles(
    panels: readonly PanelMember[],
    layout: readonly number[],
    constraints: readonly PanelConstraints[],
  ): void {
    for (const handle of this.#handles()) {
      this.#styleHandle(handle)
      const pivot = this.#pivot(handle, panels)
      if (!pivot) {
        for (const name of ['aria-controls', 'aria-valuenow', 'aria-valuemin', 'aria-valuemax'])
          set(handle.element, name, null)
        continue
      }
      const [index] = pivot
      const range = handleRange(layout, constraints, index)
      set(handle.element, 'aria-controls', panels[index]!.element.id || null)
      set(handle.element, 'aria-valuenow', ariaNumber(range.now))
      set(handle.element, 'aria-valuemin', ariaNumber(range.min))
      set(handle.element, 'aria-valuemax', ariaNumber(range.max))
    }
  }

  #styleGroup(element: HTMLElement): void {
    const horizontal = this.#horizontal
    style(element, 'display', 'flex')
    style(element, 'flex-direction', horizontal ? 'row' : 'column')
    style(element, 'flex-wrap', 'nowrap')
    style(element, 'overflow', 'hidden')
    // The group handles the drag along its axis; content still scrolls the other way.
    style(element, 'touch-action', horizontal ? 'pan-y' : 'pan-x')
    set(element, 'data-orientation', this.orientation)
    set(element, 'data-group', '')
  }

  #stylePanel(panel: PanelMember): void {
    const { element, options } = panel
    style(element, 'display', 'flex')
    style(element, 'flex-basis', '0px')
    style(element, 'flex-shrink', '1')
    if (!element.style.getPropertyValue('flex-grow')) style(element, 'flex-grow', '1')
    style(element, 'min-width', '0px')
    style(element, 'min-height', '0px')
    style(element, 'max-width', '100%')
    style(element, 'max-height', '100%')
    style(element, 'overflow', 'visible')
    set(element, 'id', this.#idOf(panel))
    set(element, 'data-panel', '')
    set(element, 'data-disabled', options.disabled ? '' : null)
    set(element, 'data-test-jn-part', 'panel')
    set(element, 'data-test-jn-value', options.id ?? null)
  }

  #styleHandle(handle: HandleMember): void {
    const { element } = handle
    const disabled = this.disabled || Boolean(handle.options.disabled)
    style(element, 'flex-grow', '0')
    style(element, 'flex-shrink', '0')
    style(element, 'touch-action', 'none')
    const cursor = this.#options.disableCursor?.()
      ? null
      : disabled
        ? 'not-allowed'
        : this.#horizontal
          ? 'col-resize'
          : 'row-resize'
    style(element, 'cursor', cursor)
    set(element, 'role', 'separator')
    set(element, 'tabindex', disabled ? null : '0')
    set(element, 'aria-orientation', this.#horizontal ? 'vertical' : 'horizontal')
    set(element, 'aria-disabled', disabled ? 'true' : null)
    set(element, 'data-orientation', this.orientation)
    set(element, 'data-separator', this.#handleState(handle))
    set(element, 'data-resizing', this.#drag?.handle === handle ? '' : null)
    set(element, 'data-test-jn-part', 'handle')
  }

  #handleState(handle: HandleMember): ResizableHandleState {
    if (this.disabled || handle.options.disabled) return 'disabled'
    if (this.#drag?.handle === handle) return 'active'
    if (handle.focused) return 'focus'
    if (handle.hovered) return 'hover'
    return 'inactive'
  }

  /** Moves the boundary at `pivot` by `delta` percent, and commits the result. */
  #move(
    panels: readonly PanelMember[],
    pivot: readonly [number, number],
    delta: number,
    trigger: ResizeTrigger,
    { complete, user }: { complete: boolean; user: boolean },
    initial?: readonly number[],
    constraints: readonly PanelConstraints[] = this.#constraints(panels),
  ): boolean {
    const current = panels.map(panel => this.#sizes.get(panel) ?? 0)
    const next = validateLayout(
      adjustLayout({
        delta,
        initial: initial ?? current,
        previous: current,
        constraints,
        pivot,
        trigger,
      }),
      constraints,
    )
    if (sameLayout(next, current)) return false
    const before = panels[pivot[0]]!
    const c = constraints[pivot[0]]!
    if (
      c.collapsible &&
      same(next[pivot[0]]!, c.collapsedSize) &&
      !same(current[pivot[0]]!, next[pivot[0]]!)
    )
      before.expandedSize = current[pivot[0]]
    this.#commit(panels, next, { complete, user })
    return true
  }

  // ----- Panel API ---------------------------------------------------------------------------

  /** @internal Resizes a panel, as its API's `resize()`. */
  resizePanel(panel: PanelMember, size: PanelSize): void {
    const panels = this.#panels()
    const index = panels.indexOf(panel)
    if (index === -1 || panels.length < 2) return
    const constraints = this.#constraints(panels)
    const current = this.#sizes.get(panel) ?? 0
    const target = toPercent(size, this.#axis, panel.element)
    const last = index === panels.length - 1
    const pivot: [number, number] = last ? [index - 1, index] : [index, index + 1]
    const c = constraints[index]!
    if (c.collapsible && same(target, c.collapsedSize) && !same(current, target))
      panel.expandedSize = current
    this.#move(
      panels,
      pivot,
      last ? current - target : target - current,
      'imperative',
      { complete: true, user: false },
      undefined,
      constraints,
    )
  }

  /** @internal */
  isCollapsed(panel: PanelMember): boolean {
    const panels = this.snapshot.panels
    const index = panels.indexOf(panel)
    if (index === -1 || !panel.options.collapsible) return false
    const c = this.#constraints([panel])[0]!
    return same(this.snapshot.sizes[index]!, c.collapsedSize)
  }

  /** @internal */
  collapse(panel: PanelMember): void {
    if (!panel.options.collapsible || this.#isCollapsedNow(panel)) return
    panel.expandedSize = this.#sizes.get(panel)
    this.resizePanel(panel, `${this.#constraints([panel])[0]!.collapsedSize}%`)
  }

  /** @internal */
  expand(panel: PanelMember): void {
    if (!this.#isCollapsedNow(panel)) return
    const c = this.#constraints([panel])[0]!
    const size = Math.max(panel.expandedSize ?? c.minSize, c.minSize)
    this.resizePanel(panel, `${size}%`)
  }

  /** @internal */
  pixelsOf(panel: PanelMember): number {
    return round(((this.#sizes.get(panel) ?? 0) / 100) * this.#axis)
  }

  #isCollapsedNow(panel: PanelMember): boolean {
    if (!panel.options.collapsible) return false
    const size = this.#sizes.get(panel)
    return size !== undefined && same(size, this.#constraints([panel])[0]!.collapsedSize)
  }

  // ----- Handles -----------------------------------------------------------------------------

  #listen(handle: HandleMember): void {
    const element = handle.element
    const listeners: [string, EventListener][] = [
      ['pointerdown', event => this.#onPointerDown(handle, event as PointerEvent)],
      ['keydown', event => this.#onKeyDown(handle, event as KeyboardEvent)],
      ['dblclick', event => this.#onDoubleClick(handle, event as MouseEvent)],
      ['pointerenter', () => this.#hover(handle, true)],
      ['pointerleave', () => this.#hover(handle, false)],
      ['focus', () => this.#focus(handle, true)],
      ['blur', () => this.#focus(handle, false)],
    ]
    for (const [type, listener] of listeners) element.addEventListener(type, listener)
    handle.unlisten = () => {
      for (const [type, listener] of listeners) element.removeEventListener(type, listener)
    }
  }

  #hover(handle: HandleMember, hovered: boolean): void {
    handle.hovered = hovered
    this.#styleHandle(handle)
  }

  #focus(handle: HandleMember, focused: boolean): void {
    handle.focused = focused
    this.#styleHandle(handle)
  }

  #canMove(handle: HandleMember): boolean {
    return !this.disabled && !handle.options.disabled
  }

  #direction(): Direction {
    return getDirection(this.#element, this.#options.dir?.())
  }

  #onPointerDown(handle: HandleMember, event: PointerEvent): void {
    if (event.defaultPrevented || event.button !== 0 || this.#drag || !this.#canMove(handle)) return
    const panels = this.#panels()
    const pivot = this.#pivot(handle, panels)
    if (!pivot) return
    const document = handle.element.ownerDocument
    const horizontal = this.#horizontal
    this.#axis = this.#measure()

    const move = (moveEvent: PointerEvent) => {
      const drag = this.#drag
      if (!drag || moveEvent.pointerId !== drag.pointerId || drag.axis <= 0) return
      const coordinate = horizontal ? moveEvent.clientX : moveEvent.clientY
      let delta = ((coordinate - drag.start) / drag.axis) * 100
      if (horizontal && this.#direction() === 'rtl') delta = -delta
      this.#move(
        panels,
        drag.pivot,
        delta,
        'pointer',
        { complete: false, user: true },
        drag.initial,
        drag.constraints,
      )
    }
    const end = (endEvent: PointerEvent) => {
      const drag = this.#drag
      if (!drag || endEvent.pointerId !== drag.pointerId) return
      const moved = !sameLayout(
        drag.initial,
        panels.map(panel => this.#sizes.get(panel) ?? 0),
      )
      this.#endDrag()
      if (moved) {
        this.#options.onLayoutChanged?.()?.(this.layout as number[], this.getLayout(), {
          isUserInteraction: true,
        })
      }
    }
    document.addEventListener('pointermove', move)
    document.addEventListener('pointerup', end)
    document.addEventListener('pointercancel', end)
    try {
      handle.element.setPointerCapture(event.pointerId)
    } catch {
      // An event a test made has no pointer to capture.
    }

    this.#drag = {
      handle,
      pointerId: event.pointerId,
      start: horizontal ? event.clientX : event.clientY,
      // In the pointer's pixels, which a transform on the page (a zoom, a scale) changes.
      axis: panels.reduce((sum, panel) => {
        const box = panel.element.getBoundingClientRect()
        return sum + (horizontal ? box.width : box.height)
      }, 0),
      initial: panels.map(panel => this.#sizes.get(panel) ?? 0),
      pivot,
      constraints: this.#constraints(panels),
      done: () => {
        document.removeEventListener('pointermove', move)
        document.removeEventListener('pointerup', end)
        document.removeEventListener('pointercancel', end)
        try {
          if (handle.element.hasPointerCapture(event.pointerId))
            handle.element.releasePointerCapture(event.pointerId)
        } catch {
          // As above.
        }
        if (!this.#options.disableCursor?.()) showCursor(document, null)
      },
    }
    if (!this.#options.disableCursor?.())
      showCursor(document, horizontal ? 'col-resize' : 'row-resize')
    this.#styleHandle(handle)
  }

  #endDrag(): void {
    const drag = this.#drag
    if (!drag) return
    this.#drag = null
    drag.done()
    this.#styleHandle(drag.handle)
  }

  #onKeyDown(handle: HandleMember, event: KeyboardEvent): void {
    if (event.defaultPrevented || !this.#canMove(handle)) return
    if (event.altKey || event.ctrlKey || event.metaKey) return
    const panels = this.#panels()
    const pivot = this.#pivot(handle, panels)
    if (!pivot) return
    const horizontal = this.#horizontal
    const step = event.shiftKey ? KEYBOARD_STEP_SHIFT : KEYBOARD_STEP
    const rtl = horizontal && this.#direction() === 'rtl'
    const user = { complete: true, user: true }

    switch (event.key) {
      case 'ArrowLeft':
      case 'ArrowRight': {
        event.preventDefault()
        if (!horizontal) return
        const forward = event.key === 'ArrowRight' ? !rtl : rtl
        this.#move(panels, pivot, forward ? step : -step, 'keyboard', user)
        return
      }
      case 'ArrowUp':
      case 'ArrowDown': {
        event.preventDefault()
        if (horizontal) return
        this.#move(panels, pivot, event.key === 'ArrowDown' ? step : -step, 'keyboard', user)
        return
      }
      case 'Home':
        event.preventDefault()
        this.#move(panels, pivot, -100, 'keyboard', user)
        return
      case 'End':
        event.preventDefault()
        this.#move(panels, pivot, 100, 'keyboard', user)
        return
      case 'Enter': {
        event.preventDefault()
        const [index] = pivot
        const panel = panels[index]!
        const constraints = this.#constraints(panels)
        const c = constraints[index]!
        if (!c.collapsible) return
        const current = this.#sizes.get(panel) ?? 0
        const target = same(current, c.collapsedSize)
          ? Math.max(panel.expandedSize ?? c.minSize, c.minSize)
          : c.collapsedSize
        this.#move(panels, pivot, target - current, 'keyboard', user, undefined, constraints)
        return
      }
      case 'F6': {
        event.preventDefault()
        const handles = this.#handles().filter(other => this.#canMove(other))
        const index = handles.indexOf(handle)
        if (index === -1 || handles.length < 2) return
        const next = event.shiftKey
          ? handles[(index - 1 + handles.length) % handles.length]!
          : handles[(index + 1) % handles.length]!
        next.element.focus({ preventScroll: true })
        return
      }
    }
  }

  #onDoubleClick(handle: HandleMember, event: MouseEvent): void {
    if (event.defaultPrevented || !this.#canMove(handle) || handle.options.disableDoubleClick)
      return
    const panels = this.#panels()
    const pivot = this.#pivot(handle, panels)
    if (!pivot) return
    const constraints = this.#constraints(panels)
    const index = pivot.find(i => constraints[i]!.defaultSize !== undefined)
    if (index === undefined) return
    const panel = panels[index]!
    const size = panel.options.defaultSize
    if (size === undefined) return
    event.preventDefault()
    this.resizePanel(panel, typeof size === 'number' ? size : `${constraints[index]!.defaultSize}%`)
  }

  /** @internal A member's arguments changed. */
  update(member: Member): void {
    if (member.kind === 'handle') this.#styleHandle(member)
    this.changed()
  }

  /** @internal */
  refresh(): void {
    const element = this.#element
    if (!element) return
    this.#styleGroup(element)
    for (const handle of this.#handles()) this.#styleHandle(handle)
  }
}

/**
 * A panel's size and its imperative API, as react-resizable-panels' `panelRef` gives:
 * `<ResizablePanel as |panel|>` yields one.
 */
export class ResizablePanelApi {
  #group: ResizableGroup | undefined
  #member: PanelMember | undefined
  @tracked private bound = 0

  /** @internal */
  bind(group: ResizableGroup, member: PanelMember): void {
    if (this.#group === group && this.#member === member) return
    this.#group = group
    this.#member = member
    this.bound += 1
  }

  /** @internal */
  unbind(member: PanelMember): void {
    if (this.#member !== member) return
    this.#group = undefined
    this.#member = undefined
  }

  /** Its size in percent of the group, or `undefined` before the group lays it out. Tracked. */
  get size(): number | undefined {
    void this.bound
    const member = this.#member
    return member ? this.#group?.sizeOf(member) : undefined
  }

  /** Whether it is collapsed now. Tracked. */
  get isCollapsed(): boolean {
    void this.bound
    const member = this.#member
    return member ? Boolean(this.#group?.isCollapsed(member)) : false
  }

  /** Its size in percent and in pixels. */
  getSize = (): ResizablePanelSize => {
    const member = this.#member
    const group = this.#group
    if (!member || !group) return { asPercentage: 0, inPixels: 0 }
    return { asPercentage: group.sizeOf(member) ?? 0, inPixels: group.pixelsOf(member) }
  }

  /** Resizes it, as its arguments take sizes: `resize("40%")`, `resize(200)` (pixels). */
  resize = (size: PanelSize): void => {
    if (this.#member) this.#group?.resizePanel(this.#member, size)
  }

  /** Collapses it to its collapsed size, if it is collapsible. */
  collapse = (): void => {
    if (this.#member) this.#group?.collapse(this.#member)
  }

  /** Expands it back to the size it had, or its minimum. */
  expand = (): void => {
    if (this.#member) this.#group?.expand(this.#member)
  }
}

function groupModifier(group: ResizableGroup) {
  return class ResizableGroupModifier extends Modifier<{
    Element: HTMLElement
    Args: { Named: { orientation?: ResizableOrientation; disabled?: boolean } }
  }> {
    #installed = false

    override modify(
      element: HTMLElement,
      _: [],
      named: { orientation?: ResizableOrientation; disabled?: boolean },
    ): void {
      // Read, so the modifier runs again when they change (ember-modifier consumes lazily).
      void named.orientation
      void named.disabled
      if (this.#installed) {
        group.refresh()
        group.changed()
        return
      }
      this.#installed = true
      const detach = group.attach(element)
      registerDestructor(this, detach)
    }
  }
}

function panelModifier(group: ResizableGroup) {
  return class ResizablePanelModifier extends Modifier<{
    Element: HTMLElement
    Args: { Named: ResizablePanelOptions }
  }> {
    #member: PanelMember | undefined

    override modify(element: HTMLElement, _: [], named: ResizablePanelOptions): void {
      const options = { ...named }
      const member = this.#member
      if (member) {
        member.options = options
        group.update(member)
        return
      }
      const created: PanelMember = (this.#member = { kind: 'panel', element, options })
      const unregister = group.register(created)
      registerDestructor(this, unregister)
    }
  }
}

function handleModifier(group: ResizableGroup) {
  return class ResizableHandleModifier extends Modifier<{
    Element: HTMLElement
    Args: { Named: ResizableHandleOptions }
  }> {
    #member: HandleMember | undefined

    override modify(element: HTMLElement, _: [], named: ResizableHandleOptions): void {
      const options = { ...named }
      const member = this.#member
      if (member) {
        member.options = options
        group.update(member)
        return
      }
      const created: HandleMember = (this.#member = {
        kind: 'handle',
        element,
        options,
        hovered: false,
        focused: false,
      })
      const unregister = group.register(created)
      registerDestructor(this, () => {
        created.unlisten?.()
        unregister()
      })
    }
  }
}

export type { PanelSize, PanelConstraints } from './layout.ts'
