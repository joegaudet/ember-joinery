import type { TOC } from '@ember/component/template-only'
import {
  Separator as SeparatorPrimitive,
  separatorAria,
  type SeparatorOrientation,
} from '@ember-joinery/primitives/separator'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import type { TagName } from '@ember-joinery/primitives/as'

export type { SeparatorOrientation }

/** What both `<Separator>` and the `asSeparator` modifier take. */
export interface SeparatorOptions {
  /** Default `horizontal`. */
  orientation?: SeparatorOrientation
  /**
   * Whether it only decorates, so assistive technology skips it. Default `true`, as upstream's:
   * most separators only draw a line. Pass `false` for one that divides content a screen
   * reader should hear divided.
   */
  decorative?: boolean
  /** The separator's name, for its harness (`data-test-jn-name`). */
  name?: string
}

/**
 * The class a separator renders. Upstream's has no semantic class, only inline utilities, so
 * it is `jn-separator`, which `separator.css` styles. (The style sheets also define a
 * `cn-separator` that upstream's component doesn't use; its `bg-border shrink-0` is the same
 * in every style, and the same as the inline utilities, so it changes nothing.)
 */
export function separatorClasses(): string {
  return 'jn-separator'
}

/** The attributes a separator renders: its ARIA and `data-orientation`, upstream's, and its harness's. */
export interface SeparatorAttributes {
  'data-slot': 'separator'
  role: 'separator' | 'none' | undefined
  'aria-orientation': 'vertical' | undefined
  'aria-hidden': 'true' | undefined
  'data-orientation': SeparatorOrientation
  'data-test-jn': 'separator'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

function decorativeOf(decorative: boolean | undefined): boolean {
  return decorative ?? true
}

/** The attributes a separator renders, as upstream's (a `div`) and for its harness. */
export function separatorAttributes({
  orientation,
  decorative,
  name,
}: SeparatorOptions = {}): SeparatorAttributes {
  return {
    'data-slot': 'separator',
    ...separatorAria({ orientation, decorative: decorativeOf(decorative), tag: 'div' }),
    'data-test-jn': 'separator',
    'data-test-jn-name': name,
  }
}

/**
 * Makes any element or component a separator, as upstream's `asChild` does: the separator's
 * class, ARIA and attributes, kept current.
 *
 *   <li {{asSeparator}}></li>
 *   <span {{asSeparator orientation="vertical"}}></span>
 *
 * It isn't named `separator`, as the pattern names every part modifier `as<Name>`.
 */
export const asSeparator: PartModifier<HTMLElement, SeparatorOptions> = part<
  HTMLElement,
  SeparatorOptions
>(options => ({ class: separatorClasses(), attributes: separatorAttributes(options) }))

export interface SeparatorSignature {
  Args: SeparatorOptions & {
    /** The tag to render instead of `div`, such as `li` between a list's items. */
    as?: TagName
  }
  Blocks: {
    /** What a decorative separator shows. Upstream's shows nothing. */
    default: []
  }
  Element: HTMLElement
}

/**
 * Visually or semantically separates content: shadcn's Separator, on the primitives'
 * `Separator`. A 1px line in the theme's `--border`, the full width, or with
 * `@orientation="vertical"` the full height of its row. Like upstream's, it is decorative
 * unless you pass `@decorative={{false}}`.
 *
 *   <Separator />
 *   <Separator @orientation="vertical" />
 */
const Separator: TOC<SeparatorSignature> = <template>
  <SeparatorPrimitive
    @as={{if @as @as "div"}}
    @decorative={{decorativeOf @decorative}}
    @orientation={{@orientation}}
    @name={{@name}}
    class="jn-separator"
    data-slot="separator"
    ...attributes
  >{{yield}}</SeparatorPrimitive>
</template>

export default Separator
