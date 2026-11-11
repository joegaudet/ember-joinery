import { Portal, PortalTarget } from '@ember-joinery/primitives/portal'

<template>
  <fieldset class="border">
    <legend>origin</legend>

    <Portal @to="name-here">
      content
    </Portal>
  </fieldset>

  <PortalTarget @name="name-here" />
</template>
