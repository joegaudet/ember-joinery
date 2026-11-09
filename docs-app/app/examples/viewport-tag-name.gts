import { InViewport } from '@ember-joinery/primitives/viewport'

/** `@tagName` picks the element InViewport renders (a `div` by default): here, a section. */
<template>
  <div data-test-jn="tagged">
    <InViewport @tagName="section" aria-label="Wrapped content" data-test-jn-part="placeholder">
      <div data-test-jn-part="content" style="border: 1px dashed; padding: 1rem;">
        Content wrapped in a section element
      </div>
    </InViewport>
  </div>
</template>
