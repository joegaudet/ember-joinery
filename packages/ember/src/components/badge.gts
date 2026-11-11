import Component from '@glimmer/component'
import { get } from '@ember/helper'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/** How a badge looks: shadcn's six variants. */
export type BadgeVariant = 'default' | 'secondary' | 'destructive' | 'outline' | 'ghost' | 'link'

/** A badge's look: what both `<Badge>` and the `asBadge` modifier take. */
export interface BadgeOptions {
  /** Default `default`. */
  variant?: BadgeVariant
  /** The badge's name, for its harness (`data-test-jn-name`). */
  name?: string
}

/**
 * The classes a badge renders: upstream's semantic classes, renamed `jn-` (`jn-badge
 * jn-badge-variant-outline`), which the style sheets style, and the `group/badge` marker.
 */
export function badgeClasses({ variant = 'default' }: BadgeOptions = {}): string {
  return `jn-badge group/badge jn-badge-variant-${variant}`
}

/** The data attributes a badge renders: upstream's, and its harness's. */
export interface BadgeAttributes {
  'data-slot': 'badge'
  'data-variant': BadgeVariant
  'data-test-jn': 'badge'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes a badge renders, as upstream's and for its harness. */
export function badgeAttributes({ variant = 'default', name }: BadgeOptions = {}): BadgeAttributes {
  return {
    'data-slot': 'badge',
    'data-variant': variant,
    'data-test-jn': 'badge',
    'data-test-jn-name': name,
  }
}

/**
 * Makes any element or component a badge, as upstream's `asChild` (and `badgeVariants`) do: it
 * adds the badge's classes and attributes, and keeps them current.
 *
 *   <a href="#link" {{asBadge}}>Open Link</a>
 *   <LinkTo @route="inbox" {{asBadge variant="secondary"}}>3 new</LinkTo>
 *
 * It isn't named `badge`, so a binding by that name can't shadow anything in a template.
 */
export const asBadge: PartModifier<HTMLElement, BadgeOptions> = part<HTMLElement, BadgeOptions>(
  options => ({ class: badgeClasses(options), attributes: badgeAttributes(options) }),
)

export interface BadgeSignature {
  Args: BadgeOptions & {
    /**
     * The tag to render instead of `span`, such as `a` for a link that looks like a badge
     * (`<Badge @as="a" href="#link">`). For a component, such as `LinkTo`, use the `asBadge`
     * modifier.
     */
    as?: TagName
  }
  Blocks: {
    /** The label, and any icons (mark an icon's side with `data-icon="inline-start"` or `"inline-end"`). */
    default: []
  }
  /** A `<span>`, or with `@as="a"`, a link. */
  Element: HTMLSpanElement | HTMLAnchorElement
}

/**
 * Displays a badge or a component that looks like a badge: shadcn's Badge, a `<span>`.
 *
 *   <Badge @variant="secondary">Secondary</Badge>
 *   <Badge @as="a" href="#link">Open Link</Badge>
 */
export default class Badge extends Component<BadgeSignature> {
  get options(): BadgeOptions {
    return { variant: this.args.variant, name: this.args.name }
  }

  /** What `asBadge` adds too, from the same functions, so both render the same. */
  get classes(): string {
    return badgeClasses(this.options)
  }

  get attributes(): BadgeAttributes {
    return badgeAttributes(this.options)
  }

  // Rendered in the template, not by the modifier, so a server-rendered page is styled; a test
  // checks the two render the same attributes.
  <template>
    <As
      @as={{@as}}
      @tag="span"
      class={{this.classes}}
      data-slot={{get this.attributes "data-slot"}}
      data-variant={{get this.attributes "data-variant"}}
      data-test-jn={{get this.attributes "data-test-jn"}}
      data-test-jn-name={{get this.attributes "data-test-jn-name"}}
      ...attributes
    >{{yield}}</As>
  </template>
}
