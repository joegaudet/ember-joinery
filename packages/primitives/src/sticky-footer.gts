import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { adoptLayoutStyles } from './-private/layout-styles.ts'

/**
 * ember-primitives' sticky-footer rules: the wrapper scrolls, and inside it a grid at least as
 * tall as the wrapper gives the content the space the footer doesn't take. The app's CSS wins,
 * where the `joinery` layer comes before its own (see `-private/layout-styles.ts`).
 */
const STYLES = `@layer joinery {
  :where([data-jn-sticky-footer]) { height: 100%; overflow: auto; }
  :where([data-jn-sticky-footer-container]) {
    min-height: 100%;
    display: grid;
    grid-template-rows: 1fr auto;
  }
}`

const styled = modifier((element: HTMLElement) =>
  adoptLayoutStyles(element, 'sticky-footer', STYLES),
)

export interface StickyFooterSignature {
  Args: {
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /**
     * The content, which scrolls, in a `<div>` of its own (`data-jn-sticky-footer-content`).
     * On a page's main layout, a `<main>` belongs in here.
     */
    content: []
    /**
     * The footer, in a `<div>` of its own (`data-jn-sticky-footer-footer`): at the bottom
     * of the wrapper while the content is short, and below the content once it overflows. A
     * `<footer>` belongs in here.
     */
    footer: []
  }
  /**
   * The wrapper, which scrolls. Its parent needs a height or a max-height for it to fill
   * (`height: 100%`).
   */
  Element: HTMLDivElement
}

/**
 * A footer that sits at the bottom of the window while there is less than a window of content,
 * and below the content, scrolled to like the rest, once there is more, as ember-primitives'
 * `StickyFooter`. It is CSS only: a scrolling wrapper, and inside it a grid at least as tall,
 * whose first row (the content) takes the space the footer doesn't.
 *
 *   <StickyFooter>
 *     <:content><main>…</main></:content>
 *     <:footer><footer>…</footer></:footer>
 *   </StickyFooter>
 *
 * Each element has an attribute to style it by: `data-jn-sticky-footer` (the wrapper, which has
 * the attributes), `data-jn-sticky-footer-container`, `-content` and `-footer`.
 * It adds no landmarks. It wraps content, so it is a wrapper for the harnesses
 * (`data-test-jn-wrapper`).
 */
export const StickyFooter: TOC<StickyFooterSignature> = <template>
  <div
    data-jn-sticky-footer
    data-test-jn="sticky-footer"
    data-test-jn-wrapper
    data-test-jn-name={{@name}}
    ...attributes
    {{styled}}
  >
    <div data-jn-sticky-footer-container>
      <div data-jn-sticky-footer-content>{{yield to="content"}}</div>
      <div data-jn-sticky-footer-footer>{{yield to="footer"}}</div>
    </div>
  </div>
</template>
