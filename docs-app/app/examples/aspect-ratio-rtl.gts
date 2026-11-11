import { AspectRatio } from '@ember-joinery/ember'

const RATIO = 16 / 9

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. An <img> in place of Next.js's <Image fill>, whose fill is absolute inset-0 h-full
    w-full, and m-0 on the <figure>: ui.shadcn.com's preflight takes away its margins, and the
    guide has no preflight.
  }}
  <figure class="m-0 w-full max-w-sm">
    <AspectRatio @ratio={{RATIO}} class="rounded-lg bg-muted">
      <img
        src="https://avatar.vercel.sh/shadcn1"
        alt="Photo"
        class="absolute inset-0 h-full w-full rounded-lg object-cover grayscale dark:brightness-20"
      />
    </AspectRatio>
    <figcaption class="mt-2 text-center text-sm text-muted-foreground">
      منظر طبيعي جميل
    </figcaption>
  </figure>
</template>
