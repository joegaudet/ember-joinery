import { HoverCard } from '@ember-joinery/primitives/hover-card'

<template>
  {{!
    The headless hover card, styled here with utility classes alone, on a link of its own: the
    pointer resting on it (or focus) opens the card, and the pointer can move onto it.
  }}
  <p class="text-sm">
    Ported from
    <HoverCard @openDelay={{200}} @closeDelay={{200}} as |h|>
      <h.Trigger href="https://ui.shadcn.com/" class="underline">shadcn/ui</h.Trigger>
      <h.Content
        @side="top"
        @sideOffset={{6}}
        class="m-0 w-60 rounded-md border-0 bg-gray-900 p-3 text-sm text-white"
      >
        Beautifully designed components, built with Radix UI and Tailwind CSS.
      </h.Content>
    </HoverCard>.
  </p>
</template>
