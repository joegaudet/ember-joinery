import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { ChevronRight, Ellipsis } from 'lucide'
import { As, type TagName } from '@ember-joinery/primitives/as'
import {
  BreadcrumbSeparator as SeparatorPrimitive,
  breadcrumbSeparatorAria,
} from '@ember-joinery/primitives/breadcrumb'
import type { PartModifier } from '@ember-joinery/primitives/part'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Icon, { type IconNode } from './icon.gts'
import {
  taggedPart,
  taggedPartModifier,
  type TaggedPartSignature,
  type TaggedPartSpec,
} from '../-private/tagged-part.gts'
import { t } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

const LIST = {
  tag: 'ol',
  class: 'jn-breadcrumb-list',
  slot: 'breadcrumb-list',
  part: 'list',
} as const satisfies TaggedPartSpec
const ITEM = {
  tag: 'li',
  class: 'jn-breadcrumb-item',
  slot: 'breadcrumb-item',
  part: 'item',
} as const satisfies TaggedPartSpec
const LINK = {
  tag: 'a',
  class: 'jn-breadcrumb-link',
  slot: 'breadcrumb-link',
  part: 'link',
} as const satisfies TaggedPartSpec
/** The current page: upstream's is a link that goes nowhere, marked current. */
const PAGE = {
  tag: 'span',
  class: 'jn-breadcrumb-page',
  slot: 'breadcrumb-page',
  part: 'page',
  attributes: { role: 'link', 'aria-disabled': 'true', 'aria-current': 'page' },
} as const satisfies TaggedPartSpec
const SEPARATOR = {
  tag: 'li',
  class: 'jn-breadcrumb-separator',
  slot: 'breadcrumb-separator',
  part: 'separator',
  attributes: breadcrumbSeparatorAria(),
} as const satisfies TaggedPartSpec
const ELLIPSIS = {
  tag: 'span',
  class: 'jn-breadcrumb-ellipsis',
  slot: 'breadcrumb-ellipsis',
  part: 'ellipsis',
  attributes: { role: 'presentation', 'aria-hidden': 'true' },
} as const satisfies TaggedPartSpec

export interface BreadcrumbSeparatorSignature {
  Args: {
    /** The tag to render instead of `li`. */
    as?: TagName
    /**
     * The icon it shows when given no block: one from `lucide`. Default lucide's
     * `chevron-right`, mirrored right to left.
     */
    icon?: IconNode
  }
  Blocks: {
    /** What it shows instead of the chevron, such as `<Icon @icon={{Dot}} />` or `/`. */
    default: []
  }
  Element: HTMLElement
}

/**
 * A separator between two crumbs: an `li` assistive technology skips, on the primitives'
 * `BreadcrumbSeparator`, showing a chevron that points the way the line reads.
 */
const BreadcrumbSeparator: TOC<BreadcrumbSeparatorSignature> = <template>
  <SeparatorPrimitive
    @as={{@as}}
    class={{SEPARATOR.class}}
    data-slot={{SEPARATOR.slot}}
    ...attributes
  >{{#if (has-block)}}{{yield}}{{else}}<Icon
        @icon={{if @icon @icon ChevronRight}}
        class="jn-rtl-flip"
      />{{/if}}</SeparatorPrimitive>
</template>

export interface BreadcrumbEllipsisSignature {
  Args: {
    /** The tag to render instead of `span`. */
    as?: TagName
    /** The icon it shows: one from `lucide`. Default lucide's `ellipsis` (`MoreHorizontalIcon`). */
    icon?: IconNode
    /** Its hidden text. Default `More`. */
    label?: string
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The crumbs left out of a long breadcrumb, collapsed into an ellipsis. */
const BreadcrumbEllipsis: TOC<BreadcrumbEllipsisSignature> = <template>
  <As
    @as={{@as}}
    @tag="span"
    role="presentation"
    aria-hidden="true"
    class={{ELLIPSIS.class}}
    data-slot={{ELLIPSIS.slot}}
    data-test-jn-part={{ELLIPSIS.part}}
    ...attributes
  >
    <Icon @icon={{if @icon @icon Ellipsis}} />
    <VisuallyHidden>{{if @label @label (t messages.breadcrumbMore)}}</VisuallyHidden>
  </As>
</template>

/** What a breadcrumb yields: its parts, each as a component and as a modifier for your own element. */
export interface BreadcrumbParts {
  /** The ordered list of crumbs (`ol`). */
  List: ComponentLike<TaggedPartSignature<HTMLOListElement>>
  /** A crumb (`li`): a `Link`, the `Page`, or an `Ellipsis`. */
  Item: ComponentLike<TaggedPartSignature<HTMLLIElement>>
  /** A link to a page above this one (`a`): give it `href`, or use `link` on your own. */
  Link: ComponentLike<TaggedPartSignature<HTMLAnchorElement>>
  /** The current page (a `span` marked `aria-current="page"`), which goes nowhere. */
  Page: ComponentLike<TaggedPartSignature<HTMLSpanElement>>
  /** A separator between two crumbs: a chevron, or what you give it. */
  Separator: typeof BreadcrumbSeparator
  /** Crumbs collapsed into an ellipsis. */
  Ellipsis: typeof BreadcrumbEllipsis
  /** Makes your own element the list. */
  list: PartModifier<HTMLElement>
  /** Makes your own element a crumb. */
  item: PartModifier<HTMLElement>
  /** `<LinkTo {{b.link}}>`: makes your own link, or a router's, a crumb's link. */
  link: PartModifier<HTMLElement>
  /** Makes your own element the current page. */
  page: PartModifier<HTMLElement>
  /** Makes your own element a separator; what it shows is yours. */
  separator: PartModifier<HTMLElement>
  /** Makes your own element the ellipsis; what it shows is yours. */
  ellipsis: PartModifier<HTMLElement>
}

const PARTS: BreadcrumbParts = {
  List: taggedPart<HTMLOListElement>(LIST),
  Item: taggedPart<HTMLLIElement>(ITEM),
  Link: taggedPart<HTMLAnchorElement>(LINK),
  Page: taggedPart<HTMLSpanElement>(PAGE),
  Separator: BreadcrumbSeparator,
  Ellipsis: BreadcrumbEllipsis,
  list: taggedPartModifier(LIST),
  item: taggedPartModifier(ITEM),
  link: taggedPartModifier(LINK),
  page: taggedPartModifier(PAGE),
  separator: taggedPartModifier(SEPARATOR),
  ellipsis: taggedPartModifier(ELLIPSIS),
}

export interface BreadcrumbSignature {
  Args: {
    /** What the navigation is called (`aria-label`). Default `breadcrumb`, as upstream's. */
    label?: string
    /** The breadcrumb's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** Its parts: a `List` of `Item`s, with a `Separator` between them. */
    default: [BreadcrumbParts]
  }
  Element: HTMLElement
}

/**
 * Displays the path to the current resource using a hierarchy of links: shadcn's Breadcrumb. A
 * `nav` named for assistive technology, around an ordered list of crumbs, with the primitives'
 * decorative separators between them.
 *
 *   <Breadcrumb as |b|>
 *     <b.List>
 *       <b.Item><b.Link href="/">Home</b.Link></b.Item>
 *       <b.Separator />
 *       <b.Item><b.Page>Breadcrumb</b.Page></b.Item>
 *     </b.List>
 *   </Breadcrumb>
 */
const Breadcrumb: TOC<BreadcrumbSignature> = <template>
  <nav
    aria-label={{if @label @label (t messages.breadcrumbLabel)}}
    data-slot="breadcrumb"
    class="jn-breadcrumb"
    data-test-jn="breadcrumb"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</nav>
</template>

export default Breadcrumb
