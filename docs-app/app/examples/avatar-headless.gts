import { Avatar } from '@ember-joinery/primitives/avatar'

<template>
  {{!
    ember-primitives' demo: the headless Avatar, styled here with Tailwind's utilities. The
    second image's URL is broken, so its fallback shows, after a 600ms delay.
  }}
  <div class="flex gap-4">
    <Avatar
      @src="https://avatars.githubusercontent.com/u/199018?v=4"
      class="flex size-16 items-center justify-center overflow-hidden rounded-2xl border-2 border-[#A300DE]"
      as |a|
    >
      <a.Image alt="GitHub profile picture of NullVoxPopuli" class="size-full object-contain" />
      <a.Fallback>NVP</a.Fallback>
    </Avatar>
    <Avatar
      @src="broken URL"
      class="flex size-16 items-center justify-center overflow-hidden rounded-2xl border-2 border-[#A300DE]"
      as |a|
    >
      <a.Image alt="GitHub profile picture of NullVoxPopuli" class="size-full object-contain" />
      <a.Fallback @delayMs={{600}}>NVP</a.Fallback>
    </Avatar>
    <Avatar
      class="flex size-16 items-center justify-center overflow-hidden rounded-2xl border-2 border-[#A300DE] text-sm"
      as |a|
    >
      <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" class="size-full object-cover" />
      <a.Fallback>{{if a.isLoading "…" "CN"}}</a.Fallback>
    </Avatar>
  </div>
</template>
