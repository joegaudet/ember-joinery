import { Portal } from '@ember-joinery/primitives/portal'

// Upstream calls it `element`, which in a template is also Ember's own `element` helper.
const target = document.createElement('div')

<template>
  <fieldset class="border">
    <legend>origin</legend>
    <Portal @to={{target}}>
      content
    </Portal>
  </fieldset>

  element is wherever we want:
  {{target}}
</template>
