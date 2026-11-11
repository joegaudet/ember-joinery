import { Switch } from '@ember-joinery/primitives/switch'

<template>
  {{!
    The headless switch, styled here with utility classes alone: you render its thumb, and its
    data-state slides it (the other way right to left).
  }}
  <div class="flex items-center gap-2 text-sm">
    <Switch
      id="headless-wifi"
      class="inline-flex h-6 w-10 items-center rounded-full border-0 bg-gray-400 p-0.5 data-[state=checked]:bg-green-700"
      as |control|
    >
      <control.Thumb
        class="block size-5 rounded-full bg-white transition-transform data-[state=checked]:translate-x-4 rtl:data-[state=checked]:-translate-x-4"
      />
    </Switch>
    <label for="headless-wifi">Wi-Fi</label>
  </div>
</template>
