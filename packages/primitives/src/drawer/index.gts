import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { PartModifier } from '../part.ts'
import {
  DialogClose,
  DialogDescription,
  DialogTitle,
  DialogTrigger,
  displayContents,
} from '../-private/dialog.gts'
import {
  DrawerController,
  type DrawerArgs,
  type DrawerDirection,
  type SnapPoint,
} from './controller.ts'
import { DrawerContent, DrawerHandle, DrawerOverlay, DrawerRoot } from './parts.gts'

export {
  DrawerController,
  DRAG_CLASS,
  type DrawerArgs,
  type DrawerDirection,
  type SnapPoint,
} from './controller.ts'
export type { DialogContentArgs as DrawerContentArgs } from '../-private/dialog.gts'

/** What a `<Drawer>` yields: a Dialog's parts and state, with vaul's. */
export interface DrawerBlockParams {
  /** A `<button>` that opens it (and closes it, if it is dismissible). */
  Trigger: WithBoundArgs<typeof DrawerTrigger, 'part'>
  /** What covers the page behind a modal drawer. A non-modal drawer renders none. */
  Overlay: WithBoundArgs<typeof DrawerOverlay, 'drawer'>
  /** The drawer itself, in the top layer while it is open, and what a drag moves. */
  Content: WithBoundArgs<typeof DrawerContent, 'drawer'>
  /** vaul's Handle: a bar to grab, which a tap moves to the next snap point. */
  Handle: WithBoundArgs<typeof DrawerHandle, 'drawer'>
  /** An `<h2>` that names it. */
  Title: WithBoundArgs<typeof DialogTitle, 'part'>
  /** A `<p>` that describes it. */
  Description: WithBoundArgs<typeof DialogDescription, 'part'>
  /** A `<button>` that closes it, if it is dismissible. */
  Close: WithBoundArgs<typeof DialogClose, 'part'>
  /** A drawer nested in this one: as it opens, this one steps back (vaul's NestedRoot). */
  Nested: WithBoundArgs<typeof Drawer, 'parent'>
  /** Makes your own element or component the trigger: `<Button {{d.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element or component close it: `<Button {{d.close}}>`. */
  close: PartModifier
  /** Makes your own element its title. */
  title: PartModifier
  /** Makes your own element its description. */
  description: PartModifier
  /** Makes your own element its handle. */
  handle: PartModifier<HTMLElement, { preventCycle?: boolean }>
  /** Whether it is open. */
  isOpen: boolean
  /** Whether it is modal. */
  isModal: boolean
  /** Whether it is being dragged. */
  isDragging: boolean
  /** The edge it comes in from. */
  direction: DrawerDirection
  /** The snap point it rests at, or `null`. */
  activeSnapPoint: SnapPoint | null
  /** Moves it to a snap point: `(fn d.setActiveSnapPoint 1)`. */
  setActiveSnapPoint: (snapPoint: SnapPoint | null) => void
  /** Opens it. */
  open: () => void
  /** Opens it, or closes it if it is dismissible. */
  toggle: () => void
  /** Opens (`true`) or closes (`false`) it, dismissible or not: `(fn d.setOpen false)`. */
  setOpen: (open: boolean) => void
  /** The `value` of the button that submitted a `<form method="dialog">` inside it, or `''`. */
  returnValue: string
  /** Its state and parts, for a component built on it (a styled drawer's own `Nested`). */
  controller: DrawerController
}

export interface DrawerSignature {
  Args: DrawerArgs
  Blocks: { default: [DrawerBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/** A `<button type="button">`, or `@as`, that opens the drawer. */
const DrawerTrigger = DialogTrigger

/**
 * A panel that slides in from an edge of the screen and follows a drag, as vaul's Drawer (which
 * shadcn's Drawer is built on), covering ember-primitives' Drawer too. It is a
 * [Dialog](./dialog) underneath, so it renders no box of its own, and yields its parts:
 *
 *   <Drawer as |d|>
 *     <d.Trigger>Open</d.Trigger>
 *     <d.Overlay />
 *     <d.Content>
 *       <d.Handle />
 *       <d.Title>Move goal</d.Title>
 *       <d.Description>Set your daily activity goal.</d.Description>
 *       <d.Close>Done</d.Close>
 *     </d.Content>
 *   </Drawer>
 *
 * Everything a Dialog does, it does: the top layer, Escape and a press outside, focus in and
 * back, the inert page and its locked scroll. Beside that, as vaul's:
 *
 * - a drag along its axis moves it, and letting go fast enough, or far enough (a quarter of it,
 *   `@closeThreshold`), closes it, while a short one springs back;
 * - `@snapPoints` gives it places to rest (`[0.25, 0.5, 1]`, fractions of the screen, or
 *   `'148px'`), and the overlay fades in from `@fadeFromIndex`;
 * - `@shouldScaleBackground` scales the element marked `data-vaul-drawer-wrapper` back while
 *   it is open;
 * - `d.Nested` is a drawer that steps this one back as it opens.
 *
 * Its slides and its resting places at the snap points are vaul's CSS, keyed on its
 * `data-vaul-*` attributes; Joinery's styled Drawer ships it in joinery.css.
 */
export class Drawer extends Component<DrawerSignature> {
  drawer = new DrawerController(this)

  <template>
    <div
      id={{this.drawer.id}}
      data-test-jn={{this.drawer.slot}}
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
      {{DrawerRoot drawer=this.drawer}}
    >
      {{yield
        (hash
          Trigger=(component DrawerTrigger part=this.drawer.trigger)
          Overlay=(component DrawerOverlay drawer=this.drawer)
          Content=(component DrawerContent drawer=this.drawer)
          Handle=(component DrawerHandle drawer=this.drawer)
          Title=(component DialogTitle part=this.drawer.title)
          Description=(component DialogDescription part=this.drawer.description)
          Close=(component DialogClose part=this.drawer.close)
          Nested=(component Drawer parent=this.drawer)
          trigger=this.drawer.trigger
          close=this.drawer.close
          title=this.drawer.title
          description=this.drawer.description
          handle=this.drawer.handle
          isOpen=this.drawer.isOpen
          isModal=this.drawer.isModal
          isDragging=this.drawer.isDragging
          direction=this.drawer.direction
          activeSnapPoint=this.drawer.activeSnapPoint
          setActiveSnapPoint=this.drawer.setActiveSnapPoint
          open=this.drawer.show
          toggle=this.drawer.toggle
          setOpen=this.drawer.setOpen
          returnValue=this.drawer.returnValue
          controller=this.drawer
        )
      }}
    </div>
  </template>
}
