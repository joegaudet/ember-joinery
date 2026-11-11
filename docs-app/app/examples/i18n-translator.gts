import { array } from '@ember/helper'
import { Slider } from '@ember-joinery/ember'

// Its thumbs are named "Minimum" and "Maximum" in English, and in the words of the app's
// translator when it registers one: the Test tab registers one in Spanish.
<template><Slider @defaultValue={{array 25 75}} class="mx-auto w-full max-w-xs" /></template>
