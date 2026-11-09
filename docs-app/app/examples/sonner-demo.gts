import { on } from '@ember/modifier'
import { Button, toast } from '@ember-joinery/ember'

const showToast = () =>
  toast('Event has been created', {
    description: 'Sunday, December 03, 2023 at 9:00 AM',
    action: {
      label: 'Undo',
      onClick: () => console.log('Undo'),
    },
  })

<template>
  <Button @variant="outline" {{on "click" showToast}}>
    Show Toast
  </Button>
</template>
