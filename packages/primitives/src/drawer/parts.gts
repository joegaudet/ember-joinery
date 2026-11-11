// The parts a Drawer renders beside a Dialog's: its content, overlay and handle, and the
// modifiers that run vaul's effects on them. Bundled into @ember-joinery/primitives/drawer.
import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import type { TOC } from '@ember/component/template-only'
import type { TagName } from '../as.gts'
import { DialogContent, DialogOverlay, type DialogContentArgs } from '../-private/dialog.gts'
import type { DrawerController } from './controller.ts'

interface DrawerEffectsSignature {
  Element: HTMLElement
  Args: { Named: { drawer: DrawerController } }
}

/**
 * What vaul's Content does as its state changes: its snap point's offset as
 * `--snap-point-height`, `data-vaul-delayed-snap-points` a frame after it mounts (so it slides
 * to its first snap point), a move to each new snap point, the scaled background while it is
 * open, and the window and keyboard listeners its snap points and inputs need.
 */
export class DrawerContentEffects extends Modifier<DrawerEffectsSignature> {
  #element: HTMLElement | undefined
  #snapPoint: { index: number | null; offset: number | undefined } | undefined
  #unscale: (() => void) | undefined
  #frame: number | undefined

  override modify(element: HTMLElement, _: [], { drawer }: { drawer: DrawerController }): void {
    if (!this.#element) this.#install(element, drawer)

    // vaul renders these on every render; they are read here, so a change runs this again.
    const offsets = drawer.snapPointsOffset
    const index = drawer.activeSnapPointIndex
    const offset = offsets[Math.max(index ?? 0, 0)]
    if (offsets.length > 0) element.style.setProperty('--snap-point-height', `${offset}px`)
    else element.style.removeProperty('--snap-point-height')

    // A new snap point, or the old one measured again: move there (but not as it mounts, where
    // its CSS slides it in from off screen).
    const previous = this.#snapPoint
    this.#snapPoint = { index, offset: index === null ? undefined : offsets[index] }
    if (
      previous &&
      index !== null &&
      index !== -1 &&
      (previous.index !== index || previous.offset !== offsets[index])
    ) {
      drawer.applySnapPoint(index)
    }

    const scale = drawer.isOpen && Boolean(drawer.args.shouldScaleBackground)
    if (scale && !this.#unscale) this.#unscale = drawer.scaleBackground(element) ?? (() => {})
    else if (!scale && this.#unscale) this.#release()
  }

  #install(element: HTMLElement, drawer: DrawerController): void {
    this.#element = element
    element.setAttribute('data-vaul-delayed-snap-points', 'false')
    const window = element.ownerDocument.defaultView
    if (drawer.hasSnapPoints && window) {
      this.#frame = window.requestAnimationFrame(() => {
        element.setAttribute('data-vaul-delayed-snap-points', 'true')
      })
    }
    window?.addEventListener('resize', drawer.measure)
    window?.visualViewport?.addEventListener('resize', drawer.onVisualViewportChange)
    registerDestructor(this, () => {
      if (this.#frame !== undefined) window?.cancelAnimationFrame(this.#frame)
      window?.removeEventListener('resize', drawer.measure)
      window?.visualViewport?.removeEventListener('resize', drawer.onVisualViewportChange)
      this.#release()
    })
  }

  #release(): void {
    const unscale = this.#unscale
    this.#unscale = undefined
    unscale?.()
  }
}

interface DrawerRootSignature {
  Element: HTMLElement
  Args: { Named: { drawer: DrawerController } }
}

/** On the root: tells the drawer each time it opens or closes, however that came about. */
export class DrawerRoot extends Modifier<DrawerRootSignature> {
  #open: boolean | undefined

  override modify(_: HTMLElement, __: [], { drawer }: { drawer: DrawerController }): void {
    const open = drawer.isOpen
    if (this.#open === undefined) {
      this.#open = open
      if (open) drawer.openChanged(true)
      drawer.rendered()
      registerDestructor(this, () => drawer.teardown())
      return
    }
    if (open === this.#open) return
    this.#open = open
    drawer.openChanged(open)
  }
}

export interface DrawerContentSignature {
  Args: DialogContentArgs & { drawer: DrawerController }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The drawer itself: a Dialog's content (in the top layer, with its role, focus and dismissal),
 * with vaul's attributes, and its pointer listeners, which drag it.
 */
export const DrawerContent: TOC<DrawerContentSignature> = <template>
  <DialogContent
    @dialog={{@drawer}}
    @as={{@as}}
    @forceMount={{@forceMount}}
    @onOpenAutoFocus={{@onOpenAutoFocus}}
    @onCloseAutoFocus={{@onCloseAutoFocus}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    ...attributes
    {{@drawer.drawerContent}}
    {{DrawerContentEffects drawer=@drawer}}
  >{{yield}}</DialogContent>
</template>

export interface DrawerOverlaySignature {
  Args: {
    drawer: DrawerController
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Keep it rendered while closed, for animating it yourself. */
    forceMount?: boolean
  }
  Element: HTMLDivElement
}

/** What covers the page behind a modal drawer, fading as the drawer is dragged. */
export const DrawerOverlay: TOC<DrawerOverlaySignature> = <template>
  <DialogOverlay
    @dialog={{@drawer}}
    @as={{@as}}
    @forceMount={{@forceMount}}
    ...attributes
    {{@drawer.drawerOverlay}}
  />
</template>

export interface DrawerHandleSignature {
  Args: {
    drawer: DrawerController
    /** Don't move to the next snap point on a tap. Default `false`. */
    preventCycle?: boolean
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * vaul's Handle: a bar to grab. A tap moves the drawer to its next snap point (and closes it
 * after the last), and with `@handleOnly` it is the only place a drag starts. It is hidden from
 * screen readers, as vaul's is: the keyboard has the drawer's own controls.
 */
export const DrawerHandle: TOC<DrawerHandleSignature> = <template>
  <div ...attributes {{@drawer.handle preventCycle=@preventCycle}}>
    <span data-vaul-handle-hitarea aria-hidden="true">{{yield}}</span>
  </div>
</template>
