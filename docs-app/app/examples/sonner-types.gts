import { on } from '@ember/modifier'
import { Button, toast } from '@ember-joinery/ember'

const showDefault = () => toast('Event has been created')
const showSuccess = () => toast.success('Event has been created')
const showInfo = () => toast.info('Be at the area 10 minutes before the event time')
const showWarning = () => toast.warning('Event start time cannot be earlier than 8am')
const showError = () => toast.error('Event has not been created')
const showPromise = () => {
  toast.promise<{ name: string }>(
    () => new Promise(resolve => setTimeout(() => resolve({ name: 'Event' }), 2000)),
    {
      loading: 'Loading...',
      success: data => `${data.name} has been created`,
      error: 'Error',
    },
  )
}

<template>
  <div class="flex flex-wrap gap-2">
    <Button @variant="outline" {{on "click" showDefault}}>
      Default
    </Button>
    <Button @variant="outline" {{on "click" showSuccess}}>
      Success
    </Button>
    <Button @variant="outline" {{on "click" showInfo}}>
      Info
    </Button>
    <Button @variant="outline" {{on "click" showWarning}}>
      Warning
    </Button>
    <Button @variant="outline" {{on "click" showError}}>
      Error
    </Button>
    <Button @variant="outline" {{on "click" showPromise}}>
      Promise
    </Button>
  </div>
</template>
