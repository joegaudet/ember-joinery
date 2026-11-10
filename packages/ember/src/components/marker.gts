import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import {
  taggedPart,
  taggedPartModifier,
  type TaggedPartSignature,
} from '../-private/tagged-part.gts'

/** How a marker looks: inline, over a bottom border, or a label between two lines. */
export type MarkerVariant = 'default' | 'separator' | 'border'

/** A marker's look: what both `<Marker>` and the `asMarker` modifier take. */
export interface MarkerOptions {
  /** Default `default`. */
  variant?: MarkerVariant
  /** The marker's name, for its harness (`data-test-jn-name`). */
  name?: string
}

/**
 * The classes a marker renders, as upstream's `markerVariants`: its semantic classes, renamed
 * `jn-` (`jn-marker jn-marker-variant-separator`), and the `group/marker` marker its parts'
 * rules look for.
 */
export function markerClasses({ variant = 'default' }: MarkerOptions = {}): string {
  return `jn-marker group/marker jn-marker-variant-${variant}`
}

/** The data attributes a marker renders: upstream's, and its harness's. */
export interface MarkerAttributes {
  'data-slot': 'marker'
  'data-variant': MarkerVariant
  'data-test-jn': 'marker'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes a marker renders, as upstream's and for its harness. */
export function markerAttributes({
  variant = 'default',
  name,
}: MarkerOptions = {}): MarkerAttributes {
  return {
    'data-slot': 'marker',
    'data-variant': variant,
    'data-test-jn': 'marker',
    'data-test-jn-name': name,
  }
}

/**
 * Makes any element or component a marker, as upstream's `asChild` does: it adds the marker's
 * classes and attributes, and keeps them current. Inside it, use the parts this module exports
 * (`MarkerIcon`, `MarkerContent`), the same ones a `<Marker>` yields.
 *
 *   <LinkTo @route="pulls" {{asMarker}}>
 *     <MarkerIcon><Icon @icon={{GitBranch}} /></MarkerIcon>
 *     <MarkerContent>View the pull request</MarkerContent>
 *   </LinkTo>
 *
 * It isn't named `marker`, as the pattern names every part modifier `as<Name>`.
 */
export const asMarker: PartModifier<HTMLElement, MarkerOptions> = part<HTMLElement, MarkerOptions>(
  options => ({ class: markerClasses(options), attributes: markerAttributes(options) }),
)

const ICON = {
  tag: 'span',
  class: 'jn-marker-icon',
  slot: 'marker-icon',
  part: 'icon',
  attributes: { 'aria-hidden': 'true' },
} as const
const CONTENT = {
  tag: 'span',
  class: 'jn-marker-content',
  slot: 'marker-content',
  part: 'content',
} as const

/**
 * The marker's icon: decoration, hidden from assistive technology (`aria-hidden`), so the
 * content beside it carries the meaning. An icon in it is 16px unless it has a size of its own.
 */
export const MarkerIcon: TOC<TaggedPartSignature> = taggedPart(ICON)

/** The marker's text. In a separator, it is centred between the two lines. */
export const MarkerContent: TOC<TaggedPartSignature> = taggedPart(CONTENT)

/** What a marker yields: its parts, each as a component and as a modifier for your own element. */
export interface MarkerParts {
  /** A decorative icon, hidden from assistive technology. */
  Icon: ComponentLike<TaggedPartSignature>
  /** The marker's text. */
  Content: ComponentLike<TaggedPartSignature>
  /** Makes your own element the icon's slot, hidden from assistive technology. */
  icon: PartModifier<HTMLElement>
  /** Makes your own element the content. */
  content: PartModifier<HTMLElement>
}

const PARTS: MarkerParts = {
  Icon: MarkerIcon,
  Content: MarkerContent,
  icon: taggedPartModifier(ICON),
  content: taggedPartModifier(CONTENT),
}

export interface MarkerSignature {
  Args: MarkerOptions & {
    /**
     * The tag to render instead of `div`, such as `a` for a marker that links somewhere
     * (`<Marker @as="a" href="/pulls/42">`) or `button` for one that acts. For a component,
     * such as `LinkTo`, use the `asMarker` modifier.
     */
    as?: TagName
  }
  Blocks: {
    default: [MarkerParts]
  }
  /** A `<div>`, or with `@as`, a link or a button. */
  Element: HTMLDivElement | HTMLAnchorElement | HTMLButtonElement
}

/**
 * Displays an inline marker in a conversation: shadcn's Marker. A status (`role="status"`, with
 * a `Spinner` in its icon), a system note, a bordered row (`@variant="border"`) or a labelled
 * separator (`@variant="separator"`):
 *
 *   <Marker role="status" as |m|>
 *     <m.Icon><Spinner /></m.Icon>
 *     <m.Content>Compacting conversation</m.Content>
 *   </Marker>
 *
 * It has no role of its own: give it `role="status"` where it reports progress. A separator's
 * lines are decoration, so its text is read as it is; don't give it the `separator` role.
 */
export default class Marker extends Component<MarkerSignature> {
  get options(): MarkerOptions {
    return { variant: this.args.variant, name: this.args.name }
  }

  /** What `asMarker` adds too, from the same functions, so both render the same. */
  get classes(): string {
    return markerClasses(this.options)
  }

  get attributes(): MarkerAttributes {
    return markerAttributes(this.options)
  }

  <template>
    <As
      @as={{@as}}
      class={{this.classes}}
      data-slot={{get this.attributes "data-slot"}}
      data-variant={{get this.attributes "data-variant"}}
      data-test-jn={{get this.attributes "data-test-jn"}}
      data-test-jn-name={{get this.attributes "data-test-jn-name"}}
      ...attributes
    >{{yield PARTS}}</As>
  </template>
}
