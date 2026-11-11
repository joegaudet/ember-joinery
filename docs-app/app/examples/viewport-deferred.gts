import { InViewport } from '@ember-joinery/primitives/viewport'

const comments = ['Great write-up.', 'This saved me a day.', 'Could it work with RTL?']

/**
 * The comments render only once they scroll near the view: scroll the box down. The slot keeps
 * their height meanwhile, so nothing jumps.
 */
<template>
  <div
    data-test-jn="article"
    tabindex="0"
    aria-label="An article"
    style="height: 12rem; overflow: auto; border: 1px solid; padding: 0 1rem; border-radius: 0.5rem;"
  >
    <p><strong>An article</strong></p>
    <p data-test-jn-part="top">Scroll down to the comments.</p>
    <p style="height: 20rem;">The article's text.</p>
    <InViewport @rootMargin="40px" data-test-jn-part="comments" style="min-height: 6rem;">
      <p><strong>Comments</strong></p>
      <ul>
        {{#each comments as |comment|}}
          <li data-test-jn-part="comment">{{comment}}</li>
        {{/each}}
      </ul>
    </InViewport>
  </div>
</template>
