import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import type { Align, Placement } from '@ember-joinery/primitives/anchor'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  HoverCard as HoverCardPrimitive,
  type HoverCardArgs,
  type HoverCardBlockParams as HoverCardPrimitiveBlockParams,
  type HoverCardContentArgs,
} from '@ember-joinery/primitives/hover-card'

/** `@align`, or upstream's `center` unless a `@placement` decides it. */
function alignOf(align: Align | undefined, placement: Placement | undefined): Align | undefined {
  return align ?? (placement ? undefined : 'center')
}

function sideOffsetOf(sideOffset: number | undefined): number {
  return sideOffset ?? 4
}

interface TriggerSignature {
  Args: {
    /** @internal The primitive's trigger, bound by the hover card. */
    Part: HoverCardPrimitiveBlockParams['Trigger']
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLAnchorElement
}

const HoverCardTrigger: TOC<TriggerSignature> = <template>
  <@Part @as={{@as}} data-slot="hover-card-trigger" ...attributes>{{yield}}</@Part>
</template>

interface ContentSignature {
  Args: HoverCardContentArgs & {
    /** @internal The primitive's Content, bound by the hover card. */
    Part: HoverCardPrimitiveBlockParams['Content']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The card itself, as upstream's `HoverCardContent`: centred, 4px from its trigger. */
const HoverCardContent: TOC<ContentSignature> = <template>
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
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    class="jn-hover-card-content"
    data-slot="hover-card-content"
    ...attributes
  >{{yield}}</@Part>
</template>

/** What a `<HoverCard>` yields. */
export interface HoverCardBlockParams {
  /** An `<a>` that opens the card. For your own element or component, use `trigger`. */
  Trigger: WithBoundArgs<typeof HoverCardTrigger, 'Part'>
  /** The card itself, in the top layer while it is open. */
  Content: WithBoundArgs<typeof HoverCardContent, 'Part'>
  /** An arrow on the card's edge (Radix's, unstyled). */
  Arrow: HoverCardPrimitiveBlockParams['Arrow']
  /** Makes your own element or component the trigger: `<Button {{h.trigger}}>`. */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it, at once. */
  setOpen: (open: boolean) => void
}

export interface HoverCardSignature {
  Args: HoverCardArgs
  Blocks: { default: [HoverCardBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * For sighted users to preview content available behind a link: shadcn's Hover Card, on the
 * primitives' headless one. It renders no box of its own, and yields its parts:
 *
 *   <HoverCard @openDelay={{10}} @closeDelay={{100}} as |h|>
 *     <Button @variant="link" {{h.trigger}}>Hover Here</Button>
 *     <h.Content>The React Framework – created and maintained by @vercel.</h.Content>
 *   </HoverCard>
 *
 * It opens once the pointer has rested on the trigger for `@openDelay` (700ms by default) or it
 * has focus, below the trigger, centred, 4px off and flipping to stay in view, and closes
 * `@closeDelay` (300ms) after the pointer leaves both. Escape or a press outside closes it.
 */
const HoverCard: TOC<HoverCardSignature> = <template>
  <HoverCardPrimitive
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @openDelay={{@openDelay}}
    @closeDelay={{@closeDelay}}
    @name={{@name}}
    ...attributes
    as |h|
  >
    {{yield
      (hash
        Trigger=(component HoverCardTrigger Part=h.Trigger)
        Content=(component HoverCardContent Part=h.Content)
        Arrow=h.Arrow
        trigger=h.trigger
        isOpen=h.isOpen
        setOpen=h.setOpen
      )
    }}
  </HoverCardPrimitive>
</template>

export default HoverCard
