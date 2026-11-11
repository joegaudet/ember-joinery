import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { staticPartModifier } from '../-private/static-part.gts'

/** How a bubble looks: shadcn's seven variants, from a strong primary to unframed content. */
export type BubbleVariant =
  'default' | 'secondary' | 'muted' | 'tinted' | 'outline' | 'ghost' | 'destructive'

/** Which side of the conversation a bubble sits on. */
export type BubbleAlign = 'start' | 'end'

/** Which edge of the bubble its reactions overlap. */
export type BubbleReactionsSide = 'top' | 'bottom'

/** Which end of that edge its reactions sit at. */
export type BubbleReactionsAlign = 'start' | 'end'

/** What the reactions part takes, as a component (`@side`) and as a modifier (`side=`). */
export interface BubbleReactionsOptions {
  /** Default `bottom`. */
  side?: BubbleReactionsSide
  /** Default `end`. */
  align?: BubbleReactionsAlign
}

/** The reactions' classes: upstream's semantic classes, renamed `jn-`. */
function reactionsClasses({ side = 'bottom', align = 'end' }: BubbleReactionsOptions = {}): string {
  return `jn-bubble-reactions jn-bubble-reactions-side-${side} jn-bubble-reactions-align-${align}`
}

/** The reactions' attributes: upstream's, and its harness's part. */
function reactionsAttributes({
  side = 'bottom',
  align = 'end',
}: BubbleReactionsOptions = {}): Record<string, string> {
  return {
    'data-slot': 'bubble-reactions',
    'data-side': side,
    'data-align': align,
    'data-test-jn-part': 'reactions',
  }
}

export interface BubbleReactionsSignature {
  Args: BubbleReactionsOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

const BubbleReactions: TOC<BubbleReactionsSignature> = <template>
  {{#let (reactionsAttributes side=@side align=@align) as |attributes|}}
    <As
      @as={{@as}}
      class={{reactionsClasses side=@side align=@align}}
      data-slot={{get attributes "data-slot"}}
      data-side={{get attributes "data-side"}}
      data-align={{get attributes "data-align"}}
      data-test-jn-part={{get attributes "data-test-jn-part"}}
      ...attributes
    >{{yield}}</As>
  {{/let}}
</template>

const CONTENT = { class: 'jn-bubble-content', slot: 'bubble-content', part: 'content' } as const

export interface BubbleContentSignature {
  Args: {
    /**
     * The tag to render instead of `div`: `button` or `a` makes the bubble a button or a link
     * (upstream's `asChild`). For a component of your own, such as `LinkTo`, use `b.content`.
     */
    as?: TagName
  }
  Blocks: { default: [] }
  /** A `<div>`, or with `@as`, a button or a link. */
  Element: HTMLDivElement | HTMLButtonElement | HTMLAnchorElement
}

const BubbleContent: TOC<BubbleContentSignature> = <template>
  <As
    @as={{@as}}
    class={{CONTENT.class}}
    data-slot={{CONTENT.slot}}
    data-test-jn-part={{CONTENT.part}}
    ...attributes
  >{{yield}}</As>
</template>

/** What a bubble yields: its parts, each as a component and as a modifier for your own element. */
export interface BubbleParts {
  /**
   * The framed surface, holding the text. `@as="button"` (or `"a"`) makes the bubble a button
   * or a link, with a focus ring; for a component of your own, such as `LinkTo`, use `content`.
   */
  Content: ComponentLike<BubbleContentSignature>
  /**
   * A row of reactions or quick actions, overlapping the bubble's edge (`@side`, default
   * `bottom`) at one end of it (`@align`, default `end`).
   */
  Reactions: ComponentLike<BubbleReactionsSignature>
  /** `<LinkTo {{b.content}}>`: makes your own element or component the content. */
  content: PartModifier<HTMLElement>
  /** Makes your own element the reactions, taking `side=` and `align=`. */
  reactions: PartModifier<HTMLElement, BubbleReactionsOptions>
}

const PARTS: BubbleParts = {
  Content: BubbleContent,
  Reactions: BubbleReactions,
  content: staticPartModifier(CONTENT),
  reactions: part<HTMLElement, BubbleReactionsOptions>(options => ({
    class: reactionsClasses(options),
    attributes: reactionsAttributes(options),
  })),
}

/** The classes a bubble renders: upstream's semantic classes, renamed `jn-`, and its marker. */
function bubbleClasses(variant: BubbleVariant = 'default'): string {
  return `jn-bubble group/bubble jn-bubble-variant-${variant}`
}

export interface BubbleSignature {
  Args: {
    /** Default `default`, the strong primary bubble. */
    variant?: BubbleVariant
    /** Default `start`. `end` puts it at the end of the row, as for your own messages. */
    align?: BubbleAlign
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The bubble's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [BubbleParts]
  }
  Element: HTMLElement
}

/**
 * Displays conversational content in a message bubble: shadcn's Bubble. It sizes to its
 * content, up to 80% of the row (a `ghost` bubble takes it all), and holds the framed content
 * and any reactions:
 *
 *   <Bubble @variant="muted" as |b|>
 *     <b.Content>I checked the registry output and removed the stale route.</b.Content>
 *     <b.Reactions role="img" aria-label="Reaction: thumbs up"><span>👍</span></b.Reactions>
 *   </Bubble>
 *
 * In a `Message`, the message's `@align` sets its side; on its own, its `@align` does.
 */
const Bubble: TOC<BubbleSignature> = <template>
  <As
    @as={{@as}}
    class={{bubbleClasses @variant}}
    data-slot="bubble"
    data-variant={{if @variant @variant "default"}}
    data-align={{if @align @align "start"}}
    data-test-jn="bubble"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default Bubble

export interface BubbleGroupSignature {
  Args: {
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The group's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * Stacks consecutive bubbles from the same sender, closer together than the conversation's
 * rows. Each bubble keeps its own `@align`.
 *
 *   <BubbleGroup>
 *     <Bubble @align="end" as |b|><b.Content>You tell me!</b.Content></Bubble>
 *     <Bubble @align="end" as |b|><b.Content>It worked yesterday.</b.Content></Bubble>
 *   </BubbleGroup>
 */
export const BubbleGroup: TOC<BubbleGroupSignature> = <template>
  <As
    @as={{@as}}
    class="jn-bubble-group"
    data-slot="bubble-group"
    data-test-jn="bubble-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>
