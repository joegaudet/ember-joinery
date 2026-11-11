import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  Tooltip as TooltipPrimitive,
  TooltipProvider as TooltipProviderPrimitive,
  type TooltipArgs,
  type TooltipBlockParams as TooltipPrimitiveBlockParams,
  type TooltipContentArgs,
  type TooltipProviderArgs,
  type TooltipState,
} from '@ember-joinery/primitives/tooltip'

/** shadcn's `TooltipProvider` opens its tooltips at once: its `delayDuration` is 0. */
const DELAY_DURATION = 0

function sideOffsetOf(sideOffset: number | undefined): number {
  return sideOffset ?? 0
}

function delayOf(delayDuration: number | undefined): number {
  return delayDuration ?? DELAY_DURATION
}

export interface TooltipProviderSignature {
  Args: TooltipProviderArgs & {
    /** The tag to render. Default `div`; use `span` inside phrasing content. */
    as?: TagName
  }
  Blocks: { default: [] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLElement
}

/**
 * Groups the tooltips inside it, as shadcn's `TooltipProvider`: they share its delays
 * (`@delayDuration`, 0 by default, as upstream's), and once one has opened the next opens at
 * once. Joinery's tooltips need no provider: those outside one behave as if in one with
 * upstream's defaults.
 */
export const TooltipProvider: TOC<TooltipProviderSignature> = <template>
  <TooltipProviderPrimitive
    @as={{@as}}
    @delayDuration={{delayOf @delayDuration}}
    @skipDelayDuration={{@skipDelayDuration}}
    @disableHoverableContent={{@disableHoverableContent}}
    ...attributes
  >{{yield}}</TooltipProviderPrimitive>
</template>

interface TriggerSignature {
  Args: {
    /** @internal The primitive's trigger, bound by the tooltip. */
    Part: TooltipPrimitiveBlockParams['Trigger']
    /** The tag to render instead. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

const TooltipTrigger: TOC<TriggerSignature> = <template>
  <@Part @as={{@as}} data-slot="tooltip-trigger" ...attributes>{{yield}}</@Part>
</template>

interface ContentSignature {
  Args: TooltipContentArgs & {
    /** @internal The primitive's parts, bound by the tooltip. */
    Part: TooltipPrimitiveBlockParams['Content']
    Arrow: TooltipPrimitiveBlockParams['Arrow']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The tooltip itself, as upstream's `TooltipContent`: above its trigger, with an arrow. */
const TooltipContent: TOC<ContentSignature> = <template>
  <@Part
    @as={{@as}}
    @forceMount={{@forceMount}}
    @side={{@side}}
    @align={{@align}}
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
    class="jn-tooltip-content"
    data-slot="tooltip-content"
    ...attributes
  >
    {{yield}}
    <@Arrow class="jn-tooltip-arrow" />
  </@Part>
</template>

/** What a `<Tooltip>` yields. */
export interface TooltipBlockParams {
  /** A `<button>` that the tooltip describes. For your own element, use `trigger`. */
  Trigger: WithBoundArgs<typeof TooltipTrigger, 'Part'>
  /** The tooltip itself, in the top layer while it is open. */
  Content: WithBoundArgs<typeof TooltipContent, 'Part' | 'Arrow'>
  /** Makes your own element or component the trigger: `<Button {{t.trigger}}>`. */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** How it is open: `delayed-open`, `instant-open` or `closed` (its `data-state`). */
  state: TooltipState
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
}

export interface TooltipSignature {
  Args: Omit<TooltipArgs, 'fallbackDelayDuration'>
  Blocks: { default: [TooltipBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * A popup that shows information about an element when it has keyboard focus or the pointer
 * rests on it: shadcn's Tooltip, on the primitives' headless one. It renders no box of its own,
 * and yields its parts:
 *
 *   <Tooltip as |t|>
 *     <Button @variant="outline" {{t.trigger}}>Hover</Button>
 *     <t.Content><p>Add to library</p></t.Content>
 *   </Tooltip>
 *
 * It opens at once (upstream's provider's delay, 0), above its trigger, flipping to stay in
 * view; Escape, a press, blur, or the pointer leaving close it. While open, the trigger's
 * `aria-describedby` names it. Its state is its own, or yours with `@open` and `@onOpenChange`.
 */
const Tooltip: TOC<TooltipSignature> = <template>
  <TooltipPrimitive
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @delayDuration={{@delayDuration}}
    @fallbackDelayDuration={{DELAY_DURATION}}
    @disableHoverableContent={{@disableHoverableContent}}
    @name={{@name}}
    ...attributes
    as |t|
  >
    {{yield
      (hash
        Trigger=(component TooltipTrigger Part=t.Trigger)
        Content=(component TooltipContent Part=t.Content Arrow=t.Arrow)
        trigger=t.trigger
        isOpen=t.isOpen
        state=t.state
        setOpen=t.setOpen
      )
    }}
  </TooltipPrimitive>
</template>

export default Tooltip
