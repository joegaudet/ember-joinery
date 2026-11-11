import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { ChevronLeft, ChevronRight, Ellipsis } from 'lucide'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Icon, { type IconNode } from './icon.gts'
import { buttonClasses, type ButtonSize, type ButtonVariant } from './button.gts'
import {
  taggedPart,
  taggedPartModifier,
  type TaggedPartSignature,
  type TaggedPartSpec,
} from '../-private/tagged-part.gts'

const CONTENT = {
  tag: 'ul',
  class: 'jn-pagination-content',
  slot: 'pagination-content',
  part: 'content',
} as const satisfies TaggedPartSpec
/** Upstream's item has no class of its own, so it gets `jn-<data-slot>`. */
const ITEM = {
  tag: 'li',
  class: 'jn-pagination-item',
  slot: 'pagination-item',
  part: 'item',
} as const satisfies TaggedPartSpec

/** Which of pagination's links it is: a page's, or the previous or next page's. */
export type PaginationLinkKind = 'link' | 'previous' | 'next'

/** What a page link, and the `link` modifier, take. */
export interface PaginationLinkOptions {
  /** Whether it is the current page's: outlined, and `aria-current="page"`. Default `false`. */
  isActive?: boolean
  /** How big it is, a Button's size. Default `icon` (square) for a page, `default` for previous and next. */
  size?: ButtonSize
}

/** What the previous and next links, and their modifiers, take. */
export interface PaginationStepOptions extends PaginationLinkOptions {
  /** What it is called for assistive technology. Default `Go to previous page` or `Go to next page`. */
  label?: string
}

const STEPS = {
  previous: { class: ' jn-pagination-previous', label: 'Go to previous page' },
  next: { class: ' jn-pagination-next', label: 'Go to next page' },
} as const

function sizeOf(kind: PaginationLinkKind, size: ButtonSize | undefined): ButtonSize {
  return size ?? (kind === 'link' ? 'icon' : 'default')
}

function variantOf(isActive: boolean | undefined): ButtonVariant {
  return isActive ? 'outline' : 'ghost'
}

/**
 * The classes a pagination link renders: upstream's is a Button (`asChild`), ghost or, for the
 * current page, outline, with `jn-pagination-link`, and `jn-pagination-previous` or
 * `jn-pagination-next` on those.
 */
export function paginationLinkClasses(
  kind: PaginationLinkKind = 'link',
  { isActive, size }: PaginationLinkOptions = {},
): string {
  const step = kind === 'link' ? '' : STEPS[kind].class
  return `${buttonClasses({ variant: variantOf(isActive), size: sizeOf(kind, size) })} jn-pagination-link${step}`
}

/** The attributes a pagination link renders: upstream's, and its harness's part. */
export interface PaginationLinkAttributes {
  'aria-current': 'page' | undefined
  /** On the previous and next links: what they are called. */
  'aria-label': string | undefined
  'data-slot': 'pagination-link'
  /** `true` or `false`, as `@isActive`; left off without it, as upstream's. */
  'data-active': 'true' | 'false' | undefined
  'data-variant': ButtonVariant
  'data-size': ButtonSize
  'data-test-jn-part': PaginationLinkKind
  [attribute: string]: string | undefined
}

/** The attributes a pagination link renders, as upstream's and for the pagination's harness. */
export function paginationLinkAttributes(
  kind: PaginationLinkKind = 'link',
  { isActive, size, label }: PaginationStepOptions = {},
): PaginationLinkAttributes {
  return {
    'aria-current': isActive ? 'page' : undefined,
    'aria-label': kind === 'link' ? label : (label ?? STEPS[kind].label),
    'data-slot': 'pagination-link',
    'data-active': isActive === undefined ? undefined : isActive ? 'true' : 'false',
    'data-variant': variantOf(isActive),
    'data-size': sizeOf(kind, size),
    'data-test-jn-part': kind,
  }
}

function linkModifier(kind: PaginationLinkKind): PartModifier<HTMLElement, PaginationStepOptions> {
  return part<HTMLElement, PaginationStepOptions>(options => ({
    class: paginationLinkClasses(kind, options),
    attributes: paginationLinkAttributes(kind, options),
  }))
}

const attributesOf = (
  kind: PaginationLinkKind,
  isActive: boolean | undefined,
  size: ButtonSize | undefined,
  label?: string,
): PaginationLinkAttributes => paginationLinkAttributes(kind, { isActive, size, label })

const classesOf = (
  kind: PaginationLinkKind,
  isActive: boolean | undefined,
  size: ButtonSize | undefined,
): string => paginationLinkClasses(kind, { isActive, size })

export interface PaginationLinkSignature {
  Args: PaginationLinkOptions & {
    /** The tag to render instead of `a`. For a router's link, use the `link` modifier. */
    as?: TagName
  }
  Blocks: {
    /** The page's number. */
    default: []
  }
  Element: HTMLAnchorElement
}

/** A page's link: a ghost icon-sized Button, outlined for the current page. */
const PaginationLink: TOC<PaginationLinkSignature> = <template>
  {{#let (attributesOf "link" @isActive @size) as |a|}}
    <As
      @as={{@as}}
      @tag="a"
      class={{classesOf "link" @isActive @size}}
      aria-current={{get a "aria-current"}}
      data-slot={{get a "data-slot"}}
      data-active={{get a "data-active"}}
      data-variant={{get a "data-variant"}}
      data-size={{get a "data-size"}}
      data-test-jn-part={{get a "data-test-jn-part"}}
      ...attributes
    >{{yield}}</As>
  {{/let}}
</template>

export interface PaginationStepSignature {
  Args: PaginationStepOptions & {
    /** The tag to render instead of `a`. For a router's link, use the `previous` or `next` modifier. */
    as?: TagName
    /** The text beside the arrow, shown from the `sm` breakpoint up. Default `Previous` or `Next`. */
    text?: string
    /** The arrow: one from `lucide`. Default lucide's `chevron-left` or `chevron-right`, mirrored right to left. */
    icon?: IconNode
  }
  Element: HTMLAnchorElement
}

/** The previous page's link: an arrow, and `Previous` on wider screens. */
const PaginationPrevious: TOC<PaginationStepSignature> = <template>
  {{#let (attributesOf "previous" @isActive @size @label) as |a|}}
    <As
      @as={{@as}}
      @tag="a"
      aria-label={{get a "aria-label"}}
      class={{classesOf "previous" @isActive @size}}
      aria-current={{get a "aria-current"}}
      data-slot={{get a "data-slot"}}
      data-active={{get a "data-active"}}
      data-variant={{get a "data-variant"}}
      data-size={{get a "data-size"}}
      data-test-jn-part={{get a "data-test-jn-part"}}
      ...attributes
    >
      <Icon @icon={{if @icon @icon ChevronLeft}} data-icon="inline-start" class="jn-rtl-flip" />
      <span class="jn-pagination-previous-text">{{if @text @text "Previous"}}</span>
    </As>
  {{/let}}
</template>

/** The next page's link: `Next` on wider screens, and an arrow. */
const PaginationNext: TOC<PaginationStepSignature> = <template>
  {{#let (attributesOf "next" @isActive @size @label) as |a|}}
    <As
      @as={{@as}}
      @tag="a"
      aria-label={{get a "aria-label"}}
      class={{classesOf "next" @isActive @size}}
      aria-current={{get a "aria-current"}}
      data-slot={{get a "data-slot"}}
      data-active={{get a "data-active"}}
      data-variant={{get a "data-variant"}}
      data-size={{get a "data-size"}}
      data-test-jn-part={{get a "data-test-jn-part"}}
      ...attributes
    >
      <span class="jn-pagination-next-text">{{if @text @text "Next"}}</span>
      <Icon @icon={{if @icon @icon ChevronRight}} data-icon="inline-end" class="jn-rtl-flip" />
    </As>
  {{/let}}
</template>

export interface PaginationEllipsisSignature {
  Args: {
    /** The tag to render instead of `span`. */
    as?: TagName
    /** The icon it shows: one from `lucide`. Default lucide's `ellipsis` (`MoreHorizontalIcon`). */
    icon?: IconNode
    /** Its hidden text. Default `More pages`. */
    label?: string
  }
  Element: HTMLSpanElement
}

/** Pages left out between two links, shown as an ellipsis that assistive technology skips. */
const PaginationEllipsis: TOC<PaginationEllipsisSignature> = <template>
  <As
    @as={{@as}}
    @tag="span"
    aria-hidden="true"
    class="jn-pagination-ellipsis"
    data-slot="pagination-ellipsis"
    data-test-jn-part="ellipsis"
    ...attributes
  >
    <Icon @icon={{if @icon @icon Ellipsis}} />
    <VisuallyHidden>{{if @label @label "More pages"}}</VisuallyHidden>
  </As>
</template>

/** What a pagination yields: its parts, each as a component and as a modifier for your own element. */
export interface PaginationParts {
  /** The list of links (`ul`). */
  Content: ComponentLike<TaggedPartSignature<HTMLUListElement>>
  /** One link's place in the list (`li`). */
  Item: ComponentLike<TaggedPartSignature<HTMLLIElement>>
  /** A page's link: `@isActive` for the current page. */
  Link: typeof PaginationLink
  /** The previous page's link. */
  Previous: typeof PaginationPrevious
  /** The next page's link. */
  Next: typeof PaginationNext
  /** Pages left out, as an ellipsis. */
  Ellipsis: typeof PaginationEllipsis
  /** Makes your own element the list. */
  content: PartModifier<HTMLElement>
  /** Makes your own element an item. */
  item: PartModifier<HTMLElement>
  /** `<LinkTo {{p.link isActive=true}}>`: makes a router's link a page's link. */
  link: PartModifier<HTMLElement, PaginationStepOptions>
  /** Makes a router's link the previous page's; its arrow and text are yours. */
  previous: PartModifier<HTMLElement, PaginationStepOptions>
  /** Makes a router's link the next page's; its arrow and text are yours. */
  next: PartModifier<HTMLElement, PaginationStepOptions>
  /** Makes your own element the ellipsis; what it shows is yours. */
  ellipsis: PartModifier<HTMLElement>
}

const PARTS: PaginationParts = {
  Content: taggedPart<HTMLUListElement>(CONTENT),
  Item: taggedPart<HTMLLIElement>(ITEM),
  Link: PaginationLink,
  Previous: PaginationPrevious,
  Next: PaginationNext,
  Ellipsis: PaginationEllipsis,
  content: taggedPartModifier(CONTENT),
  item: taggedPartModifier(ITEM),
  link: linkModifier('link'),
  previous: linkModifier('previous'),
  next: linkModifier('next'),
  ellipsis: part<HTMLElement>(() => ({
    class: 'jn-pagination-ellipsis',
    attributes: {
      'aria-hidden': 'true',
      'data-slot': 'pagination-ellipsis',
      'data-test-jn-part': 'ellipsis',
    },
  })),
}

export interface PaginationSignature {
  Args: {
    /** What the navigation is called (`aria-label`). Default `pagination`, as upstream's. */
    label?: string
    /** The pagination's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** Its parts: `Content`, a list of `Item`s, each holding a link or the ellipsis. */
    default: [PaginationParts]
  }
  Element: HTMLElement
}

/**
 * Pagination with page navigation, next and previous links: shadcn's Pagination. A `nav`
 * named for assistive technology, centred, around a list of links that look like ghost
 * Buttons, the current page's outlined.
 *
 *   <Pagination as |p|>
 *     <p.Content>
 *       <p.Item><p.Previous href="?page=1" /></p.Item>
 *       <p.Item><p.Link href="?page=1">1</p.Link></p.Item>
 *       <p.Item><p.Link href="?page=2" @isActive={{true}}>2</p.Link></p.Item>
 *       <p.Item><p.Ellipsis /></p.Item>
 *       <p.Item><p.Next href="?page=3" /></p.Item>
 *     </p.Content>
 *   </Pagination>
 */
const Pagination: TOC<PaginationSignature> = <template>
  <nav
    role="navigation"
    aria-label={{if @label @label "pagination"}}
    data-slot="pagination"
    class="jn-pagination"
    data-test-jn="pagination"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</nav>
</template>

export default Pagination
