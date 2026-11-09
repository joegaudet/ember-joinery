import { Hero } from '@ember-joinery/primitives/hero'

/**
 * Upstream's page has no live example. A Hero covers the whole viewport, so this one is sized
 * to fit the preview with Tailwind classes, which win over its own rules (they are in
 * `@layer joinery`): on a page of its own, leave them off.
 */
<template>
  <Hero
    class="h-80 w-full overflow-hidden rounded-lg bg-neutral-900 text-white"
    aria-label="Introducing Joinery"
    role="region"
  >
    <div class="flex h-full flex-col items-center justify-center gap-4 p-8 text-center">
      <h2 class="text-4xl font-bold">Joinery</h2>
      <p class="max-w-md text-neutral-300">
        Every shadcn/ui component for Ember, on a headless primitives layer.
      </p>
      <button type="button" class="rounded-md bg-white px-4 py-2 font-medium text-neutral-900">
        Get started
      </button>
    </div>
    {{! The Hero is position: relative, so this sits along its bottom edge. }}
    <p class="absolute inset-x-0 bottom-0 p-3 text-center text-sm text-neutral-400">
      Scroll for more
    </p>
  </Hero>
</template>
