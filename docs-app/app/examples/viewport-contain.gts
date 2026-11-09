import { InViewport } from '@ember-joinery/primitives/viewport'

/**
 * The default mode: once near the view, the content renders inside InViewport's own element,
 * which stays in the page around it. Scroll the box down.
 */
<template>
  <div
    data-test-jn="scroller"
    tabindex="0"
    aria-label="Contain mode"
    style="height: 170px; overflow: auto; border: 1px solid; padding: 1rem; border-radius: 0.5rem;"
  >
    <div style="height: 600px;">
      <div style="display: grid; gap: 4rem;">
        <span data-test-jn-part="top">Scroll down</span>
        <span>Scroll down</span>
        <span>Scroll down</span>
      </div>

      <InViewport @mode="contain" data-test-jn-part="placeholder">
        <div data-test-jn-part="content" style="border: 1px dashed; padding: 1rem;">
          Content in contain mode
        </div>
      </InViewport>
    </div>
  </div>
</template>
