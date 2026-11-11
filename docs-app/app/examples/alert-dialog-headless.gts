import { AlertDialog } from '@ember-joinery/primitives/alert-dialog'

/**
 * The headless AlertDialog: always modal, with the alertdialog role, focus on Cancel when it
 * opens, and no closing on a press outside.
 */
<template>
  <AlertDialog as |d|>
    <d.Trigger class="rounded-md border px-3 py-1.5 text-sm">Delete file</d.Trigger>
    <d.Overlay class="fixed inset-0 bg-black/40" />
    <d.Content
      class="fixed top-1/2 left-1/2 grid w-80 -translate-x-1/2 -translate-y-1/2 gap-3 rounded-lg bg-background p-5 text-foreground shadow-lg"
    >
      <d.Title class="text-lg font-semibold">Delete this file?</d.Title>
      <d.Description class="text-sm text-muted-foreground">
        It goes for good: there is no undo.
      </d.Description>
      <div class="flex justify-end gap-2">
        <d.Cancel class="rounded-md border px-3 py-1.5 text-sm">Keep it</d.Cancel>
        <d.Action class="rounded-md bg-destructive px-3 py-1.5 text-sm text-white">
          Delete
        </d.Action>
      </div>
    </d.Content>
  </AlertDialog>
</template>
