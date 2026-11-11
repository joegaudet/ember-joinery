import { array } from '@ember/helper'
import { Slider } from '@ember-joinery/ember'

<template>
  <Slider @defaultValue={{array 75}} @max={{100}} @step={{1}} class="mx-auto w-full max-w-xs" />
</template>
