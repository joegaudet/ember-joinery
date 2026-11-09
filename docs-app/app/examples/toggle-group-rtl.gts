import { ToggleGroup } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream's passes its language's `dir`; Joinery's group takes it from the nearest
    `dir`, so the items run from the right and the left arrow moves forward.
  }}
  <ToggleGroup @variant="outline" @type="single" @defaultValue="list" as |g|>
    <g.Item @value="list" aria-label="قائمة">
      قائمة
    </g.Item>
    <g.Item @value="grid" aria-label="شبكة">
      شبكة
    </g.Item>
    <g.Item @value="cards" aria-label="بطاقات">
      بطاقات
    </g.Item>
  </ToggleGroup>
</template>
