import { Item, Spinner } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left, in upstream's Arabic. Upstream leaves the Spinner's built-in
    "Loading"; Joinery's is in Arabic too ("جاري التحميل"), as a right-to-left page would name
    it. It is read aloud, not drawn, so the screenshot is the same.
  }}
  <div class="flex w-full max-w-xs flex-col gap-4 [--radius:1rem]">
    <Item @variant="muted" as |i|>
      <i.Media>
        <Spinner @label="جاري التحميل" />
      </i.Media>
      <i.Content>
        <i.Title class="line-clamp-1">جاري معالجة الدفع...</i.Title>
      </i.Content>
      <i.Content class="flex-none justify-end">
        <span class="text-sm tabular-nums">١٠٠.٠٠ دولار</span>
      </i.Content>
    </Item>
  </div>
</template>
