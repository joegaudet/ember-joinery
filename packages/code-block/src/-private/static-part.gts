import type { TOC } from '@ember/component/template-only'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/**
 * What a part with no state of its own renders, always the same: the code block's header,
 * title, actions or footer. Its class (upstream's semantic class, renamed `jn-`), its
 * `data-slot` as upstream's, and its `data-test-jn-part`, for the block's harness.
 */
export interface StaticPartSpec {
  readonly class: string
  readonly slot: string
  readonly part: string
}

export interface StaticPartSignature {
  Args: {
    /**
     * The tag to render instead of `div`. For a component of your own, such as `LinkTo`, use
     * the part's modifier (`<LinkTo {{b.title}}>`).
     */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The attributes a static part renders: upstream's `data-slot`, and its harness's part. */
export function staticPartAttributes(spec: StaticPartSpec): Record<string, string> {
  return { 'data-slot': spec.slot, 'data-test-jn-part': spec.part }
}

/**
 * The part as a component: a `div` (or `@as`) with the part's class and attributes, then the
 * caller's (`...attributes` last, so a caller's `class` adds to the part's and their attributes
 * win). They are rendered in the template, so a server-rendered page is styled.
 */
export function staticPart(spec: StaticPartSpec): TOC<StaticPartSignature> {
  return <template>
    <As
      @as={{@as}}
      class={{spec.class}}
      data-slot={{spec.slot}}
      data-test-jn-part={{spec.part}}
      ...attributes
    >{{yield}}</As>
  </template>
}

/**
 * The part as a modifier, for an element or component of the caller's own
 * (`<a href="…" {{b.title}}>`): the same class and attributes as its component.
 */
export function staticPartModifier(spec: StaticPartSpec): PartModifier<HTMLElement> {
  return part<HTMLElement>(() => ({ class: spec.class, attributes: staticPartAttributes(spec) }))
}
