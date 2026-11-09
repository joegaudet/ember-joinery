import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Button, toast, type ToastPosition } from '@ember-joinery/ember'

const showAt = (position: ToastPosition) => toast('Event has been created', { position })

<template>
  <div class="flex flex-wrap justify-center gap-2">
    <Button @variant="outline" {{on "click" (fn showAt "top-left")}}>
      Top Left
    </Button>
    <Button @variant="outline" {{on "click" (fn showAt "top-center")}}>
      Top Center
    </Button>
    <Button @variant="outline" {{on "click" (fn showAt "top-right")}}>
      Top Right
    </Button>
    <Button @variant="outline" {{on "click" (fn showAt "bottom-left")}}>
      Bottom Left
    </Button>
    <Button @variant="outline" {{on "click" (fn showAt "bottom-center")}}>
      Bottom Center
    </Button>
    <Button @variant="outline" {{on "click" (fn showAt "bottom-right")}}>
      Bottom Right
    </Button>
  </div>
</template>
