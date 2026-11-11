import { inIframe } from '@ember-joinery/primitives/iframe'

/** What an embeddable page might show, depending on whether it is in a frame. */
<template>
  <p data-test-jn="embed-notice">
    {{#if (inIframe)}}
      This page is embedded in another.
      <a href="https://joegaudet.com/ember-joinery/guide/" target="_top">Open it on its own</a>.
    {{else}}
      This page is open on its own, not in a frame.
    {{/if}}
  </p>
</template>
