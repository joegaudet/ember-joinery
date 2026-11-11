/* global HTMLElementTagNameMap -- a DOM type, which ESLint's browser globals don't list */
import type { TOC } from '@ember/component/template-only'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/**
 * What a part with no state of its own renders, always the same: a table's row, a breadcrumb's
 * list. Its tag (upstream's: `tr`, `ol`), its classes (upstream's semantic class, renamed `jn-`,
 * or `jn-<data-slot>` where upstream gives none), its `data-slot` as upstream's, and its
 * `data-test-jn-part`, for the component's harness. `attributes` holds the ARIA upstream gives
 * it, such as a breadcrumb page's `aria-current`.
 */
export interface TaggedPartSpec {
  readonly tag: keyof HTMLElementTagNameMap
  readonly class: string
  readonly slot: string
  readonly part: string
  readonly attributes?: Readonly<Partial<Record<TaggedPartAttribute, string>>>
}

/** The attributes a tagged part may render besides its class, slot and part. */
export type TaggedPartAttribute = 'role' | 'aria-current' | 'aria-disabled' | 'aria-hidden'

export interface TaggedPartSignature<E extends Element = HTMLElement> {
  Args: {
    /**
     * The tag to render instead of the part's own, such as `th` for a cell that heads its row
     * (`<t.Cell @as="th" scope="row">`). For a component of your own, use the part's modifier
     * (`<LinkTo {{b.link}}>`).
     */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/** The attributes a tagged part renders: upstream's `data-slot` (and any others), and its harness's part. */
export function taggedPartAttributes(spec: TaggedPartSpec): Record<string, string> {
  return { ...spec.attributes, 'data-slot': spec.slot, 'data-test-jn-part': spec.part }
}

/**
 * The part as a component: its tag (or `@as`) with the part's classes and attributes, then the
 * caller's (`...attributes` last, so a caller's `class` adds to the part's and their attributes
 * win). It renders them in the template, so a server-rendered page is styled.
 */
export function taggedPart<E extends Element = HTMLElement>(
  spec: TaggedPartSpec,
): TOC<TaggedPartSignature<E>> {
  const attributes = taggedPartAttributes(spec)
  const attribute = (name: TaggedPartAttribute): string | undefined => attributes[name]
  const Part: TOC<TaggedPartSignature> = <template>
    <As
      @as={{@as}}
      @tag={{spec.tag}}
      class={{spec.class}}
      role={{attribute "role"}}
      aria-current={{attribute "aria-current"}}
      aria-disabled={{attribute "aria-disabled"}}
      aria-hidden={{attribute "aria-hidden"}}
      data-slot={{spec.slot}}
      data-test-jn-part={{spec.part}}
      ...attributes
    >{{yield}}</As>
  </template>
  // Its element is the part's own tag's, which the spec names at runtime.
  return Part as unknown as TOC<TaggedPartSignature<E>>
}

/**
 * The part as a modifier, for an element or component of the caller's own
 * (`<LinkTo {{b.link}}>`): the same classes and attributes as its component.
 */
export function taggedPartModifier<E extends Element = HTMLElement>(
  spec: TaggedPartSpec,
): PartModifier<E> {
  return part<E>(() => ({ class: spec.class, attributes: taggedPartAttributes(spec) }))
}
