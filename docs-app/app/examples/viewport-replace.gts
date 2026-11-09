import { InViewport } from '@ember-joinery/primitives/viewport'

/**
 * `@mode="replace"`: once near the view, the content takes the place of InViewport's element,
 * which goes. Scroll the box down.
 */
<template>
  <div
    data-test-jn="scroller"
    tabindex="0"
    aria-label="Replace mode"
    style="height: 170px; overflow: auto; border: 1px solid; padding: 1rem; border-radius: 0.5rem;"
  >
    <div style="height: 600px;">
      <div style="display: grid; gap: 4rem;">
        <span data-test-jn-part="top">Scroll down</span>
        <span>Scroll down</span>
        <span>Scroll down</span>
      </div>

      <InViewport @mode="replace" data-test-jn-part="placeholder">
        <div data-test-jn-part="content" style="border: 1px dashed; padding: 1rem;">
          This replaces the placeholder
        </div>
      </InViewport>
    </div>
  </div>
</template>
