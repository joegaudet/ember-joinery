import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'

<template>
  <button type="button" class="icon-button">
    <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
      <path d="M18 6 6 18M6 6l12 12" stroke="currentColor" stroke-width="2" />
    </svg>
    <VisuallyHidden>Close</VisuallyHidden>
  </button>
</template>
