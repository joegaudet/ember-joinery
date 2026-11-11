import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'
import { separatorAria, type SeparatorOrientation } from '@ember-joinery/primitives/separator'

/** How an item looks: transparent, outlined, or on a muted background. */
export type ItemVariant = 'default' | 'outline' | 'muted'

/** How roomy an item is. */
export type ItemSize = 'default' | 'sm' | 'xs'

/** How an item's media looks: as it is, an icon, or an image cropped to a square. */
export type ItemMediaVariant = 'default' | 'icon' | 'image'

/** An item's look: what both `<Item>` and the `asItem` modifier take. */
export interface ItemOptions {
  /** Default `default`. */
  variant?: ItemVariant
  /** Default `default`. */
  size?: ItemSize
  /** The item's name, for its harness (`data-test-jn-name`). */
  name?: string
}

/**
 * The classes an item renders: upstream's semantic classes, renamed `jn-` (`jn-item
 * jn-item-variant-outline jn-item-size-sm`), and the `group/item` marker its parts' rules look
 * for.
 */
export function itemClasses({ variant = 'default', size = 'default' }: ItemOptions = {}): string {
  return `jn-item group/item jn-item-variant-${variant} jn-item-size-${size}`
}

/** The data attributes an item renders: upstream's, and its harness's. */
export interface ItemAttributes {
  'data-slot': 'item'
  'data-variant': ItemVariant
  'data-size': ItemSize
  'data-test-jn': 'item'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes an item renders, as upstream's and for its harness. */
export function itemAttributes({
  variant = 'default',
  size = 'default',
  name,
}: ItemOptions = {}): ItemAttributes {
  return {
    'data-slot': 'item',
    'data-variant': variant,
    'data-size': size,
    'data-test-jn': 'item',
    'data-test-jn-name': name,
  }
}

/**
 * Makes any element or component an item, as upstream's `asChild` does: it adds the item's
 * classes and attributes, and keeps them current. Inside it, use the parts this module exports
 * (`ItemMedia`, `ItemContent`, `ItemTitle`…), the same ones an `<Item>` yields.
 *
 *   <LinkTo @route="dashboard" {{asItem variant="outline"}}>
 *     <ItemContent><ItemTitle>Dashboard</ItemTitle></ItemContent>
 *   </LinkTo>
 *
 * It isn't named `item`, as the pattern names every part modifier `as<Name>`.
 */
export const asItem: PartModifier<HTMLElement, ItemOptions> = part<HTMLElement, ItemOptions>(
  options => ({ class: itemClasses(options), attributes: itemAttributes(options) }),
)

/** What the media part takes, as a component (`@variant`) and as a modifier (`variant=`). */
export interface ItemMediaOptions {
  /** Default `default`. */
  variant?: ItemMediaVariant
}

function mediaClasses({ variant = 'default' }: ItemMediaOptions = {}): string {
  return `jn-item-media jn-item-media-variant-${variant}`
}

function mediaAttributes({ variant = 'default' }: ItemMediaOptions = {}): Record<string, string> {
  return { 'data-slot': 'item-media', 'data-variant': variant, 'data-test-jn-part': 'media' }
}

export interface ItemMediaSignature {
  Args: ItemMediaOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * An item's media: an icon (`@variant="icon"` sizes it), an image (`@variant="image"` crops it
 * to a square), or an avatar. Beside a description, it aligns with the title.
 */
export const ItemMedia: TOC<ItemMediaSignature> = <template>
  {{#let (mediaAttributes variant=@variant) as |attributes|}}
    <As
      @as={{@as}}
      class={{mediaClasses variant=@variant}}
      data-slot={{get attributes "data-slot"}}
      data-variant={{get attributes "data-variant"}}
      data-test-jn-part={{get attributes "data-test-jn-part"}}
      ...attributes
    >{{yield}}</As>
  {{/let}}
</template>

const CONTENT = { class: 'jn-item-content', slot: 'item-content', part: 'content' } as const
const TITLE = { class: 'jn-item-title', slot: 'item-title', part: 'title' } as const
const DESCRIPTION = {
  class: 'jn-item-description',
  slot: 'item-description',
  part: 'description',
} as const
const ACTIONS = { class: 'jn-item-actions', slot: 'item-actions', part: 'actions' } as const
const HEADER = { class: 'jn-item-header', slot: 'item-header', part: 'header' } as const
const FOOTER = { class: 'jn-item-footer', slot: 'item-footer', part: 'footer' } as const

/** The title and description. A second one after it keeps to its content's width. */
export const ItemContent: TOC<StaticPartSignature> = staticPart(CONTENT)

/** The item's title, on one line. */
export const ItemTitle: TOC<StaticPartSignature> = staticPart(TITLE)

/** Its description, muted, on up to two lines; a link in it is underlined. Upstream's is a `p`. */
export const ItemDescription: TOC<StaticPartSignature> = <template>
  <As
    @as={{@as}}
    @tag="p"
    class={{DESCRIPTION.class}}
    data-slot={{DESCRIPTION.slot}}
    data-test-jn-part={{DESCRIPTION.part}}
    ...attributes
  >{{yield}}</As>
</template>

/** Buttons or other controls, after the content. */
export const ItemActions: TOC<StaticPartSignature> = staticPart(ACTIONS)

/** A row above the rest, the item's full width: an image, a heading. */
export const ItemHeader: TOC<StaticPartSignature> = staticPart(HEADER)

/** A row below the rest, the item's full width. */
export const ItemFooter: TOC<StaticPartSignature> = staticPart(FOOTER)

/** What an item yields: its parts, each as a component and as a modifier for your own element. */
export interface ItemParts {
  /** An icon, an image or an avatar, before the content. */
  Media: ComponentLike<ItemMediaSignature>
  /** Wraps the title and description. */
  Content: ComponentLike<StaticPartSignature>
  /** The title, on one line. */
  Title: ComponentLike<StaticPartSignature>
  /** The description, muted, on up to two lines. */
  Description: ComponentLike<StaticPartSignature>
  /** Buttons or other controls, after the content. */
  Actions: ComponentLike<StaticPartSignature>
  /** A full-width row above the rest. */
  Header: ComponentLike<StaticPartSignature>
  /** A full-width row below the rest. */
  Footer: ComponentLike<StaticPartSignature>
  /** `<img {{i.media variant="image"}}>`: makes your own element the media. */
  media: PartModifier<HTMLElement, ItemMediaOptions>
  /** Makes your own element the content. */
  content: PartModifier<HTMLElement>
  /** `<LinkTo {{i.title}}>`: makes your own element or component the title. */
  title: PartModifier<HTMLElement>
  /** Makes your own element the description. */
  description: PartModifier<HTMLElement>
  /** Makes your own element the actions. */
  actions: PartModifier<HTMLElement>
  /** Makes your own element the header. */
  header: PartModifier<HTMLElement>
  /** Makes your own element the footer. */
  footer: PartModifier<HTMLElement>
}

const PARTS: ItemParts = {
  Media: ItemMedia,
  Content: ItemContent,
  Title: ItemTitle,
  Description: ItemDescription,
  Actions: ItemActions,
  Header: ItemHeader,
  Footer: ItemFooter,
  media: part<HTMLElement, ItemMediaOptions>(options => ({
    class: mediaClasses(options),
    attributes: mediaAttributes(options),
  })),
  content: staticPartModifier(CONTENT),
  title: staticPartModifier(TITLE),
  description: staticPartModifier(DESCRIPTION),
  actions: staticPartModifier(ACTIONS),
  header: staticPartModifier(HEADER),
  footer: staticPartModifier(FOOTER),
}

export interface ItemSignature {
  Args: ItemOptions & {
    /**
     * The tag to render instead of `div`, such as `a` for an item that is a link
     * (`<Item @as="a" href="/dashboard">`), which then takes the hover and focus styles. For a
     * component, such as `LinkTo`, use the `asItem` modifier.
     */
    as?: TagName
  }
  Blocks: {
    default: [ItemParts]
  }
  /** A `<div>`, or with `@as="a"`, a link. */
  Element: HTMLDivElement | HTMLAnchorElement
}

/**
 * A versatile component for displaying content with media, title, description, and actions:
 * shadcn's Item. A flex row that wraps, so a header or footer takes a row of its own.
 *
 *   <Item @variant="outline" as |i|>
 *     <i.Media @variant="icon"><Icon @icon={{Inbox}} /></i.Media>
 *     <i.Content>
 *       <i.Title>Title</i.Title>
 *       <i.Description>Description</i.Description>
 *     </i.Content>
 *     <i.Actions><Button>Action</Button></i.Actions>
 *   </Item>
 */
export default class Item extends Component<ItemSignature> {
  get options(): ItemOptions {
    return { variant: this.args.variant, size: this.args.size, name: this.args.name }
  }

  /** What `asItem` adds too, from the same functions, so both render the same. */
  get classes(): string {
    return itemClasses(this.options)
  }

  get attributes(): ItemAttributes {
    return itemAttributes(this.options)
  }

  <template>
    <As
      @as={{@as}}
      class={{this.classes}}
      data-slot={{get this.attributes "data-slot"}}
      data-variant={{get this.attributes "data-variant"}}
      data-size={{get this.attributes "data-size"}}
      data-test-jn={{get this.attributes "data-test-jn"}}
      data-test-jn-name={{get this.attributes "data-test-jn-name"}}
      ...attributes
    >{{yield PARTS}}</As>
  </template>
}

/** What the separator part takes, as a component and as a modifier. */
export interface ItemSeparatorOptions {
  /** Default `horizontal`. */
  orientation?: SeparatorOrientation
  /** Whether assistive technology skips it. Default `true`, as upstream's. */
  decorative?: boolean
}

export interface ItemSeparatorSignature {
  Args: ItemSeparatorOptions & {
    /** The tag to render instead of `div`, such as `hr` or `li`. */
    as?: TagName
  }
  Element: HTMLElement
}

const SEPARATOR_CLASS = 'jn-item-separator'

/**
 * The separator's attributes: the primitives' `separatorAria()`, as upstream's ItemSeparator
 * renders its Separator (horizontal and decorative unless you say), with its own `data-slot`.
 * `tag` is the component's `@as`; the modifier's element is taken for a `div`.
 */
function separatorAttributes({
  orientation = 'horizontal',
  decorative = true,
  tag,
}: ItemSeparatorOptions & { tag?: string } = {}): Record<string, string | undefined> {
  return {
    'data-slot': 'item-separator',
    ...separatorAria({ orientation, decorative, tag }),
    'data-test-jn-part': 'separator',
  }
}

/**
 * A line between a group's items: upstream's ItemSeparator, which renders its Separator, so
 * it is decorative unless you pass `@decorative={{false}}`. An `<ItemGroup>` yields it too
 * (`<g.Separator />`).
 */
export const ItemSeparator: TOC<ItemSeparatorSignature> = <template>
  {{#let
    (separatorAttributes orientation=@orientation decorative=@decorative tag=@as)
    as |attributes|
  }}
    <As
      @as={{@as}}
      class={{SEPARATOR_CLASS}}
      data-slot={{get attributes "data-slot"}}
      role={{get attributes "role"}}
      aria-orientation={{get attributes "aria-orientation"}}
      aria-hidden={{get attributes "aria-hidden"}}
      data-orientation={{get attributes "data-orientation"}}
      data-test-jn-part={{get attributes "data-test-jn-part"}}
      ...attributes
    />
  {{/let}}
</template>

/** What an item group yields: its separator, as a component and as a modifier. */
export interface ItemGroupParts {
  /** A line between two items. */
  Separator: ComponentLike<ItemSeparatorSignature>
  /** `<hr {{g.separator}}>`: makes your own element the separator. */
  separator: PartModifier<HTMLElement, ItemSeparatorOptions>
}

const GROUP_PARTS: ItemGroupParts = {
  Separator: ItemSeparator,
  separator: part<HTMLElement, ItemSeparatorOptions>(options => ({
    class: SEPARATOR_CLASS,
    attributes: separatorAttributes(options),
  })),
}

export interface ItemGroupSignature {
  Args: {
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The group's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The items, and separators between them. Give each item `role="listitem"`. */
    default: [ItemGroupParts]
  }
  Element: HTMLElement
}

/**
 * Groups related items into a list: a column with a gap, the `list` role, and a separator to
 * put between items. Give each item `role="listitem"`, so assistive technology reads a list
 * of them.
 *
 *   <ItemGroup as |g|>
 *     <Item role="listitem" as |i|>…</Item>
 *     <g.Separator />
 *     <Item role="listitem" as |i|>…</Item>
 *   </ItemGroup>
 */
export const ItemGroup: TOC<ItemGroupSignature> = <template>
  <As
    @as={{@as}}
    role="list"
    class="jn-item-group group/item-group"
    data-slot="item-group"
    data-test-jn="item-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield GROUP_PARTS}}</As>
</template>
