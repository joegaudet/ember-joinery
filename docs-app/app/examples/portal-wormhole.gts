import { Portal } from '@ember-joinery/primitives/portal'
import { InViewport } from '@ember-joinery/primitives/viewport'

<template>
  <InViewport>
    <fieldset class="border">
      <legend>origin</legend>
      Two portals:
      <Portal @wormhole="wormhole-target">
        content
      </Portal>

      <Portal @wormhole="#wormhole-target">
        extra content
      </Portal>
    </fieldset>

    element is wherever we want:
    <div id="wormhole-target"></div>
  </InViewport>
</template>
