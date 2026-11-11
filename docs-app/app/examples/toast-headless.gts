import { on } from '@ember/modifier'
import { Toaster, toast } from '@ember-joinery/primitives/toast'

// A Toaster of its own (`@id`), so its toasts stay out of the guide's: a toast made with its
// `toasterId` shows here. Without shadcn's tokens, sonner's CSS gives it sonner's own look.
const save = () =>
  toast.promise(new Promise(resolve => setTimeout(resolve, 1000)), {
    loading: 'Saving…',
    success: 'Saved',
    error: 'Could not save',
    toasterId: 'headless',
  })

<template>
  <button type="button" {{on "click" save}}>Save</button>
  <Toaster @id="headless" @position="bottom-center" @containerAriaLabel="Saving" />
</template>
