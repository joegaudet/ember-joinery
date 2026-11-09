import { AspectRatio } from '@ember-joinery/primitives/aspect-ratio'

const WIDESCREEN = 16 / 9

<template>
  <div class="w-64">
    <AspectRatio
      @ratio={{WIDESCREEN}}
      class="flex items-center justify-center rounded-md border border-dashed text-sm"
    >
      16 : 9
    </AspectRatio>
  </div>
</template>
