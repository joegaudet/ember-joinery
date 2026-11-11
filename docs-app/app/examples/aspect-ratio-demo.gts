import { AspectRatio } from '@ember-joinery/ember'

const RATIO = 16 / 9

<template>
  {{! An <img> in place of Next.js's <Image fill>, whose fill is absolute inset-0 h-full w-full. }}
  <div class="w-full max-w-sm">
    <AspectRatio @ratio={{RATIO}} class="rounded-lg bg-muted">
      <img
        src="https://avatar.vercel.sh/shadcn1"
        alt="Photo"
        class="absolute inset-0 h-full w-full rounded-lg object-cover grayscale dark:brightness-20"
      />
    </AspectRatio>
  </div>
</template>
