import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'

/** How roomy a card is: `sm` uses smaller spacing. */
export type CardSize = 'default' | 'sm'

const HEADER = {
  class: 'jn-card-header group/card-header',
  slot: 'card-header',
  part: 'header',
} as const
const TITLE = { class: 'jn-card-title jn-font-heading', slot: 'card-title', part: 'title' } as const
const DESCRIPTION = {
  class: 'jn-card-description',
  slot: 'card-description',
  part: 'description',
} as const
const ACTION = { class: 'jn-card-action', slot: 'card-action', part: 'action' } as const
const CONTENT = { class: 'jn-card-content', slot: 'card-content', part: 'content' } as const
const FOOTER = { class: 'jn-card-footer', slot: 'card-footer', part: 'footer' } as const

/** What a card yields: its parts, each as a component and as a modifier for your own element. */
export interface CardParts {
  /** The header: a title, a description, and an action beside them. */
  Header: ComponentLike<StaticPartSignature>
  /** The card's title, in the theme's heading font. */
  Title: ComponentLike<StaticPartSignature>
  /** Helper text under the title, muted. */
  Description: ComponentLike<StaticPartSignature>
  /** A button or badge, in the header's top inline-end corner. */
  Action: ComponentLike<StaticPartSignature>
  /** The card's body. */
  Content: ComponentLike<StaticPartSignature>
  /** Actions and secondary content at the bottom, on a muted band. */
  Footer: ComponentLike<StaticPartSignature>
  /** `<header {{c.header}}>`: makes your own element the header. */
  header: PartModifier<HTMLElement>
  /** `<LinkTo {{c.title}}>`: makes your own element or component the title. */
  title: PartModifier<HTMLElement>
  /** Makes your own element the description. */
  description: PartModifier<HTMLElement>
  /** Makes your own element the action's container. */
  action: PartModifier<HTMLElement>
  /** Makes your own element the content. */
  content: PartModifier<HTMLElement>
  /** Makes your own element the footer. */
  footer: PartModifier<HTMLElement>
}

const PARTS: CardParts = {
  Header: staticPart(HEADER),
  Title: staticPart(TITLE),
  Description: staticPart(DESCRIPTION),
  Action: staticPart(ACTION),
  Content: staticPart(CONTENT),
  Footer: staticPart(FOOTER),
  header: staticPartModifier(HEADER),
  title: staticPartModifier(TITLE),
  description: staticPartModifier(DESCRIPTION),
  action: staticPartModifier(ACTION),
  content: staticPartModifier(CONTENT),
  footer: staticPartModifier(FOOTER),
}

export interface CardSignature {
  Args: {
    /** Default `default`. `sm` uses smaller spacing. */
    size?: CardSize
    /** The tag to render instead of `div`, such as `section` or `article`. */
    as?: TagName
    /** The card's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The card's parts, and anything else: an image first goes edge to edge at the top. */
    default: [CardParts]
  }
  Element: HTMLElement
}

/**
 * Displays a card with header, content, and footer: shadcn's Card. The `--card-spacing` CSS
 * variable sets the space between its sections and the inset of its parts (`@size="sm"` makes
 * it smaller); set it on the card to change both.
 *
 *   <Card as |c|>
 *     <c.Header>
 *       <c.Title>Card Title</c.Title>
 *       <c.Description>Card Description</c.Description>
 *       <c.Action>Card Action</c.Action>
 *     </c.Header>
 *     <c.Content><p>Card Content</p></c.Content>
 *     <c.Footer><p>Card Footer</p></c.Footer>
 *   </Card>
 */
const Card: TOC<CardSignature> = <template>
  <As
    @as={{@as}}
    class="jn-card group/card"
    data-slot="card"
    data-size={{if @size @size "default"}}
    data-test-jn="card"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default Card
