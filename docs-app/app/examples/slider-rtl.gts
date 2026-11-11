import { array } from '@ember/helper'
import { Slider } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor). Upstream's
    passes its language's `dir` to the slider; Joinery's takes it from the nearest `dir`, so
    the range fills from the right and the left arrow steps up. Upstream's has no text to
    translate.
  }}
  <Slider @defaultValue={{array 75}} @max={{100}} @step={{1}} class="mx-auto w-full max-w-xs" />
</template>
