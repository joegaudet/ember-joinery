import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import type { Align, Placement } from '@ember-joinery/primitives/anchor'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  Popover as PopoverPrimitive,
  type PopoverArgs,
  type PopoverBlockParams as PopoverPrimitiveBlockParams,
  type PopoverContentArgs,
} from '@ember-joinery/primitives/popover'

/** `@align`, or upstream's `center` unless a `@placement` decides it. */
function alignOf(align: Align | undefined, placement: Placement | undefined): Align | undefined {
  return align ?? (placement ? undefined : 'center')
}

function sideOffsetOf(sideOffset: number | undefined): number {
  return sideOffset ?? 4
}

interface PartSignature<E extends Element, Part> {
  Args: {
    /** @internal The primitive's part, bound by the popover. */
    Part: Part
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

const PopoverTrigger: TOC<
  PartSignature<HTMLButtonElement, PopoverPrimitiveBlockParams['Trigger']>
> = <template>
  <@Part @as={{@as}} data-slot="popover-trigger" ...attributes>{{yield}}</@Part>
</template>

const PopoverAnchor: TOC<PartSignature<HTMLDivElement, PopoverPrimitiveBlockParams['Anchor']>> =
  <template>
    <@Part @as={{@as}} data-slot="popover-anchor" ...attributes>{{yield}}</@Part>
  </template>

/** Upstream's title is a `<div>`; it names the content (its `aria-labelledby`). */
const PopoverTitle: TOC<PartSignature<HTMLElement, PopoverPrimitiveBlockParams['Title']>> =
  <template>
    <@Part
      @as={{if @as @as "div"}}
      class="jn-popover-title"
      data-slot="popover-title"
      ...attributes
    >{{yield}}</@Part>
  </template>

/** A `<p>` that describes the content (its `aria-describedby`). */
const PopoverDescription: TOC<
  PartSignature<HTMLParagraphElement, PopoverPrimitiveBlockParams['Description']>
> = <template>
  <@Part
    @as={{@as}}
    class="jn-popover-description"
    data-slot="popover-description"
    ...attributes
  >{{yield}}</@Part>
</template>

export interface PopoverHeaderSignature {
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** Holds a popover's title and description, as upstream's `PopoverHeader`. */
const PopoverHeader: TOC<PopoverHeaderSignature> = <template>
  <div class="jn-popover-header" data-slot="popover-header" ...attributes>{{yield}}</div>
</template>

interface ContentSignature {
  Args: PopoverContentArgs & {
    /** @internal The primitive's Content, bound by the popover. */
    Part: PopoverPrimitiveBlockParams['Content']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The popover itself, as upstream's `PopoverContent`: centred, 4px from its trigger. */
const PopoverContent: TOC<ContentSignature> = <template>
  <@Part
    @as={{@as}}
    @forceMount={{@forceMount}}
    @side={{@side}}
    @align={{alignOf @align @placement}}
    @sideOffset={{sideOffsetOf @sideOffset}}
    @alignOffset={{@alignOffset}}
    @avoidCollisions={{@avoidCollisions}}
    @collisionPadding={{@collisionPadding}}
    @arrowPadding={{@arrowPadding}}
    @sticky={{@sticky}}
    @hideWhenDetached={{@hideWhenDetached}}
    @placement={{@placement}}
    @offsetOptions={{@offsetOptions}}
    @flipOptions={{@flipOptions}}
    @shiftOptions={{@shiftOptions}}
    @middleware={{@middleware}}
    @strategy={{@strategy}}
    @onOpenAutoFocus={{@onOpenAutoFocus}}
    @onCloseAutoFocus={{@onCloseAutoFocus}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    class="jn-popover-content"
    data-slot="popover-content"
    ...attributes
  >{{yield}}</@Part>
</template>

/** What a `<Popover>` yields: its parts, their modifiers, and its state. */
export interface PopoverBlockParams {
  /** A `<button>` that opens and closes it. For your own element, use `trigger`. */
  Trigger: WithBoundArgs<typeof PopoverTrigger, 'Part'>
  /** Something to place the content against instead of the trigger. */
  Anchor: WithBoundArgs<typeof PopoverAnchor, 'Part'>
  /** The popover itself, in the top layer while it is open. */
  Content: WithBoundArgs<typeof PopoverContent, 'Part'>
  /** Holds the title and description. */
  Header: typeof PopoverHeader
  /** Names the content. */
  Title: WithBoundArgs<typeof PopoverTitle, 'Part'>
  /** Describes the content. */
  Description: WithBoundArgs<typeof PopoverDescription, 'Part'>
  /** A `<button>` that closes it (Radix's, unstyled). */
  Close: PopoverPrimitiveBlockParams['Close']
  /** An arrow on the content's edge (Radix's, unstyled). */
  Arrow: PopoverPrimitiveBlockParams['Arrow']
  /** Makes your own element or component the trigger: `<Button {{p.trigger}}>`. */
  trigger: PartModifier
  /** Makes your own element the anchor. */
  anchor: PartModifier
  /** Makes your own element or component close the popover. */
  close: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** Opens it. */
  open: () => void
  /** Opens it if it is closed, and closes it if it is open. */
  toggle: () => void
  /** Opens (`true`) or closes (`false`) it: `(fn p.setOpen false)`. */
  setOpen: (open: boolean) => void
}

export interface PopoverSignature {
  Args: PopoverArgs
  Blocks: { default: [PopoverBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * Displays rich content in a layer, triggered by a button: shadcn's Popover, on the
 * primitives' headless one. It renders no box of its own, and yields its parts:
 *
 *   <Popover as |p|>
 *     <Button @variant="outline" {{p.trigger}}>Open Popover</Button>
 *     <p.Content @align="start">
 *       <p.Header>
 *         <p.Title>Title</p.Title>
 *         <p.Description>Description text here.</p.Description>
 *       </p.Header>
 *     </p.Content>
 *   </Popover>
 *
 * Its state is its own, or yours with `@open` and `@onOpenChange` (`@defaultOpen` starts it
 * open). The content is in the top layer while open, placed against the trigger (below it,
 * centred, 4px off, flipping to stay in view); Escape or a press outside closes it, and focus
 * moves in and back.
 */
const Popover: TOC<PopoverSignature> = <template>
  <PopoverPrimitive
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @modal={{@modal}}
    @name={{@name}}
    @placement={{@placement}}
    @offsetOptions={{@offsetOptions}}
    @flipOptions={{@flipOptions}}
    @shiftOptions={{@shiftOptions}}
    @middleware={{@middleware}}
    @strategy={{@strategy}}
    ...attributes
    as |p|
  >
    {{yield
      (hash
        Trigger=(component PopoverTrigger Part=p.Trigger)
        Anchor=(component PopoverAnchor Part=p.Anchor)
        Content=(component PopoverContent Part=p.Content)
        Header=PopoverHeader
        Title=(component PopoverTitle Part=p.Title)
        Description=(component PopoverDescription Part=p.Description)
        Close=p.Close
        Arrow=p.Arrow
        trigger=p.trigger
        anchor=p.anchor
        close=p.close
        isOpen=p.isOpen
        open=p.open
        toggle=p.toggle
        setOpen=p.setOpen
      )
    }}
  </PopoverPrimitive>
</template>

export default Popover
