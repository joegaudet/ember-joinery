import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import {
  CollapsibleContent as HeadlessContent,
  CollapsibleState,
} from '@ember-joinery/primitives/collapsible'
import { part, type PartModifier, type PartSpec } from '@ember-joinery/primitives/part'

/** A part's spec, with its `data-slot` added. */
function withSlot(spec: PartSpec, slot: string): PartSpec {
  return { ...spec, attributes: { ...spec.attributes, 'data-slot': slot } }
}

export interface CollapsibleTriggerSignature {
  Args: {
    /** The tag to render. Default `button`. */
    as?: TagName
    /** @internal Bound by the collapsible. */
    part: PartModifier
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** The button that opens and closes the collapsible, yielded as `c.Trigger`. */
const CollapsibleTrigger: TOC<CollapsibleTriggerSignature> = <template>
  <As
    @as={{@as}}
    @tag="button"
    type="button"
    data-slot="collapsible-trigger"
    ...attributes
    {{@part}}
  >{{yield}}</As>
</template>

export interface CollapsibleContentSignature {
  Args: {
    /** Keep the content rendered and shown while closed, for animating it yourself. */
    forceMount?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by the collapsible. */
    collapsible: CollapsibleState
    /** @internal Bound by the collapsible. */
    part: PartModifier<HTMLElement, { shown: boolean }>
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * What the collapsible shows and hides, yielded as `c.Content`. Its element stays in the
 * document, `hidden` and empty while closed, and stays shown until an exit animation of yours
 * (on `data-state="closed"`) ends.
 */
const CollapsibleContent: TOC<CollapsibleContentSignature> = <template>
  <HeadlessContent
    @as={{@as}}
    @forceMount={{@forceMount}}
    @collapsible={{@collapsible}}
    @part={{@part}}
    data-slot="collapsible-content"
    ...attributes
  >{{yield}}</HeadlessContent>
</template>

/** What `<Collapsible>` yields. */
export interface CollapsibleYield {
  /** The button that opens and closes it: `<c.Trigger>Details</c.Trigger>`. */
  Trigger: WithBoundArgs<typeof CollapsibleTrigger, 'part'>
  /** What it shows and hides: `<c.Content>…</c.Content>`. */
  Content: WithBoundArgs<typeof CollapsibleContent, 'collapsible' | 'part'>
  /**
   * The trigger, as a modifier on your own element or component, as upstream's `asChild`:
   * `<Button @variant="ghost" {{c.trigger}}>`.
   */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** Opens or closes it. */
  toggle: () => void
}

export interface CollapsibleSignature {
  Args: {
    /** The controlled open state. Pass `@onOpenChange` too, to hear the trigger. */
    open?: boolean
    /** Whether it starts open, when uncontrolled. Default `false`. */
    defaultOpen?: boolean
    /** Called with each new open state. */
    onOpenChange?: (open: boolean) => void
    /** Whether the trigger can't open or close it. */
    disabled?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `CollapsibleHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [CollapsibleYield] }
  Element: HTMLDivElement
}

/**
 * An interactive component which expands and collapses a panel: shadcn's Collapsible, on the
 * primitives' `CollapsibleState`. Like upstream's, it adds only its `data-slot`s to Radix's
 * parts, so it looks like whatever you put in it:
 *
 *   <Collapsible class="flex flex-col gap-2" as |c|>
 *     <Button @variant="ghost" @size="icon" {{c.trigger}}>…</Button>
 *     <c.Content class="flex flex-col gap-2">…</c.Content>
 *   </Collapsible>
 *
 * It is uncontrolled unless given `@open` (with `@onOpenChange`); `@defaultOpen` starts it open.
 */
export default class Collapsible extends Component<CollapsibleSignature> {
  collapsible = new CollapsibleState({
    open: () => this.args.open,
    defaultOpen: () => this.args.defaultOpen,
    onOpenChange: () => this.args.onOpenChange,
    disabled: () => this.args.disabled,
  })

  /** The headless trigger, with upstream's `data-slot`. */
  trigger: PartModifier = part(() =>
    withSlot(this.collapsible.triggerSpec(), 'collapsible-trigger'),
  )

  /** The headless content, with upstream's `data-slot`. */
  content: PartModifier<HTMLElement, { shown: boolean }> = part<HTMLElement, { shown: boolean }>(
    named => withSlot(this.collapsible.contentSpec(named), 'collapsible-content'),
  )

  <template>
    <As
      @as={{@as}}
      @tag="div"
      data-slot="collapsible"
      data-state={{this.collapsible.dataState}}
      data-disabled={{if this.collapsible.isDisabled ""}}
      data-test-jn="collapsible"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{yield
        (hash
          Trigger=(component CollapsibleTrigger part=this.trigger)
          Content=(component CollapsibleContent collapsible=this.collapsible part=this.content)
          trigger=this.trigger
          isOpen=this.collapsible.isOpen
          toggle=this.collapsible.toggle
        )
      }}
    </As>
  </template>
}
