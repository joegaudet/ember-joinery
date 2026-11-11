import type { TOC } from '@ember/component/template-only'

export interface InHeadSignature {
  Blocks: {
    /** What goes in the document's `<head>`: `<meta>`, `<link>`, `<script>`, `<style>`… */
    default: []
  }
}

const documentHead = (): HTMLHeadElement => document.head

/**
 * Renders its block into the document's `<head>`, after what is already there, and takes it
 * out again when it stops rendering. For a page's own `<meta>` tags, a stylesheet only one
 * route needs, or a script loaded on demand:
 *
 *   {{#if this.wantsPrint}}
 *     <InHead><link rel="stylesheet" href="/print.css" /></InHead>
 *   {{/if}}
 *
 * It is ember-primitives' `InHead`.
 */
export const InHead: TOC<InHeadSignature> = <template>
  {{#in-element (documentHead) insertBefore=null}}
    {{yield}}
  {{/in-element}}
</template>
