import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { adoptLayoutStyles } from './-private/layout-styles.ts'

/**
 * ember-primitives' hero rules: the whole viewport, with the dynamic viewport units so it fits
 * a phone's browser as its toolbars come and go. `position: relative`, so what's inside can be
 * placed along its edges. Any CSS of the app's wins.
 */
const STYLES = `@layer joinery {
  :where([data-jn-hero]) { width: 100dvw; height: 100dvh; position: relative; }
}`

const styled = modifier((element: HTMLElement) => {
  adoptLayoutStyles(element, 'hero', STYLES)
})

export interface HeroSignature {
  Args: {
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** What the hero features: an image or a video, a headline, a call to action. */
    default: []
  }
  /** The hero's element, as wide and tall as the viewport. */
  Element: HTMLDivElement
}

/**
 * A layout for featuring large, eye-catching content across the whole browser window, as
 * ember-primitives' `Hero`: `100dvw` by `100dvh` (the dynamic viewport units, which follow a
 * phone's toolbars) and `position: relative`, so headers and footers inside can be placed along
 * its edges.
 *
 *   <Hero class="landing">
 *     <h1>Joinery</h1>
 *     <a href="/guide">Get started</a>
 *   </Hero>
 *
 * Its rules are in `@layer joinery` at no specificity, so a class of the app's resizes it. It
 * adds no landmark: put `<main>` or `<header>` inside or around it as the page needs. It wraps
 * content, so it is a wrapper for the harnesses (`data-test-jn-wrapper`).
 */
export const Hero: TOC<HeroSignature> = <template>
  <div
    data-jn-hero
    data-test-jn="hero"
    data-test-jn-wrapper
    data-test-jn-name={{@name}}
    ...attributes
    {{styled}}
  >
    {{yield}}
  </div>
</template>
