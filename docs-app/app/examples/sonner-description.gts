import { on } from '@ember/modifier'
import { Button, toast } from '@ember-joinery/ember'

const showToast = () =>
  toast('Event has been created', {
    description: 'Monday, January 3rd at 6:00pm',
  })

<template>
  <Button {{on "click" showToast}} @variant="outline" class="w-fit">
    Show Toast
  </Button>
</template>
