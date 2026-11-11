import { hash } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  Drawer as DrawerPrimitive,
  type DrawerArgs,
  type DrawerBlockParams,
  type DrawerContentArgs,
  type DrawerDirection,
  type SnapPoint,
} from '@ember-joinery/primitives/drawer'
import type { PartModifier } from '@ember-joinery/primitives/part'

export type { DrawerDirection, SnapPoint } from '@ember-joinery/primitives/drawer'

export interface DrawerContentSignature {
  Args: DrawerContentArgs & {
    /** The drawer, bound by `<Drawer>`. */
    drawer: DrawerBlockParams
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The panel, against its edge of the screen behind its overlay, with the handle upstream draws
 * at the top of a bottom drawer. It renders upstream's DrawerPortal: the overlay, then the
 * content, in the top layer.
 */
const DrawerContent: TOC<DrawerContentSignature> = <template>
  <@drawer.Overlay class="jn-drawer-overlay" @forceMount={{@forceMount}} />
  <@drawer.Content
    class="jn-drawer-content group/drawer-content"
    @as={{@as}}
    @forceMount={{@forceMount}}
    @onOpenAutoFocus={{@onOpenAutoFocus}}
    @onCloseAutoFocus={{@onCloseAutoFocus}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    ...attributes
  >
    <div class="jn-drawer-handle" data-test-jn-part="handle"></div>
    {{yield}}
  </@drawer.Content>
</template>

export interface DrawerSectionSignature {
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The title and description: centred in a drawer from the top or bottom. */
const DrawerHeader: TOC<DrawerSectionSignature> = <template>
  <div class="jn-drawer-header" data-slot="drawer-header" ...attributes>{{yield}}</div>
</template>

/** The actions, stacked at the bottom. */
const DrawerFooter: TOC<DrawerSectionSignature> = <template>
  <div class="jn-drawer-footer" data-slot="drawer-footer" ...attributes>{{yield}}</div>
</template>

export interface DrawerTextSignature<E extends Element> {
  Args: {
    /** The headless part it styles, bound by `<Drawer>`. */
    base: DrawerBlockParams['Title'] | DrawerBlockParams['Description']
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** An `<h2>` that names the drawer. */
const DrawerTitle: TOC<DrawerTextSignature<HTMLHeadingElement>> = <template>
  <@base class="jn-drawer-title jn-font-heading" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

/** A `<p>` that describes the drawer. */
const DrawerDescription: TOC<DrawerTextSignature<HTMLParagraphElement>> = <template>
  <@base class="jn-drawer-description" @as={{@as}} ...attributes>{{yield}}</@base>
</template>

/** What a `<Drawer>` yields. */
export interface DrawerYield {
  /** A `<button>` that opens it. To use your own, such as a `<Button>`, use `trigger`. */
  Trigger: DrawerBlockParams['Trigger']
  /** The drawer itself, with its overlay and handle. */
  Content: WithBoundArgs<typeof DrawerContent, 'drawer'>
  Header: typeof DrawerHeader
  Footer: typeof DrawerFooter
  Title: WithBoundArgs<typeof DrawerTitle, 'base'>
  Description: WithBoundArgs<typeof DrawerDescription, 'base'>
  /** An unstyled `<button>` that closes it. To use your own, use `close`. */
  Close: DrawerBlockParams['Close']
  /** A drawer nested in this one, styled as this one: as it opens, this one steps back. */
  Nested: WithBoundArgs<typeof Drawer, 'parent'>
  /** vaul's Handle, unstyled: a bar a tap moves to the next snap point. */
  Handle: DrawerBlockParams['Handle']
  /** Makes your own element or component the trigger: `<Button {{d.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element or component close it: `<Button {{d.close}}>`. */
  close: PartModifier
  isOpen: boolean
  isModal: boolean
  isDragging: boolean
  direction: DrawerDirection
  activeSnapPoint: SnapPoint | null
  setActiveSnapPoint: (snapPoint: SnapPoint | null) => void
  open: () => void
  toggle: () => void
  setOpen: (open: boolean) => void
  returnValue: string
}

export interface DrawerSignature {
  Args: DrawerArgs
  Blocks: { default: [DrawerYield] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A drawer for React, as shadcn calls it: a panel that slides in from an edge of the screen and
 * follows a drag, on the headless one in `@ember-joinery/primitives/drawer` (vaul's Drawer).
 *
 *   <Drawer as |d|>
 *     <Button @variant="outline" {{d.trigger}}>Open Drawer</Button>
 *     <d.Content>
 *       <d.Header>
 *         <d.Title>Move Goal</d.Title>
 *         <d.Description>Set your daily activity goal.</d.Description>
 *       </d.Header>
 *       <d.Footer>
 *         <Button>Submit</Button>
 *         <Button @variant="outline" {{d.close}}>Cancel</Button>
 *       </d.Footer>
 *     </d.Content>
 *   </Drawer>
 */
const Drawer: TOC<DrawerSignature> = <template>
  <DrawerPrimitive
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @modal={{@modal}}
    @name={{@name}}
    @onClose={{@onClose}}
    @direction={{@direction}}
    @dismissible={{@dismissible}}
    @snapPoints={{@snapPoints}}
    @activeSnapPoint={{@activeSnapPoint}}
    @defaultActiveSnapPoint={{@defaultActiveSnapPoint}}
    @onActiveSnapPointChange={{@onActiveSnapPointChange}}
    @fadeFromIndex={{@fadeFromIndex}}
    @snapToSequentialPoint={{@snapToSequentialPoint}}
    @closeThreshold={{@closeThreshold}}
    @scrollLockTimeout={{@scrollLockTimeout}}
    @handleOnly={{@handleOnly}}
    @shouldScaleBackground={{@shouldScaleBackground}}
    @setBackgroundColorOnScale={{@setBackgroundColorOnScale}}
    @noBodyStyles={{@noBodyStyles}}
    @autoFocus={{@autoFocus}}
    @repositionInputs={{@repositionInputs}}
    @fixed={{@fixed}}
    @onDrag={{@onDrag}}
    @onRelease={{@onRelease}}
    @onAnimationEnd={{@onAnimationEnd}}
    @parent={{@parent}}
    ...attributes
    as |d|
  >
    {{yield
      (hash
        Trigger=d.Trigger
        Content=(component DrawerContent drawer=d)
        Header=DrawerHeader
        Footer=DrawerFooter
        Title=(component DrawerTitle base=d.Title)
        Description=(component DrawerDescription base=d.Description)
        Close=d.Close
        Nested=(component Drawer parent=d.controller)
        Handle=d.Handle
        trigger=d.trigger
        close=d.close
        isOpen=d.isOpen
        isModal=d.isModal
        isDragging=d.isDragging
        direction=d.direction
        activeSnapPoint=d.activeSnapPoint
        setActiveSnapPoint=d.setActiveSnapPoint
        open=d.open
        toggle=d.toggle
        setOpen=d.setOpen
        returnValue=d.returnValue
      )
    }}
  </DrawerPrimitive>
</template>

export default Drawer
