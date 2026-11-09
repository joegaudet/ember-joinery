import { Dialog } from '@ember-joinery/primitives/dialog'

/**
 * The headless Dialog, styled with nothing but utility classes: it brings the behaviour (the
 * top layer, focus, Escape, a press outside, the inert page and the scroll lock), and you bring
 * the look.
 */
<template>
  <Dialog as |d|>
    <d.Trigger class="rounded-md border px-3 py-1.5 text-sm">Edit profile</d.Trigger>
    <d.Overlay class="fixed inset-0 bg-black/40" />
    <d.Content
      class="fixed top-1/2 left-1/2 grid w-80 -translate-x-1/2 -translate-y-1/2 gap-3 rounded-lg bg-background p-5 text-foreground shadow-lg"
    >
      <d.Title class="text-lg font-semibold">Edit profile</d.Title>
      <d.Description class="text-sm text-muted-foreground">
        Make changes to your profile here.
      </d.Description>
      <label class="grid gap-1 text-sm">
        Name
        <input class="rounded-md border px-2 py-1" value="Pedro Duarte" />
      </label>
      <div class="flex justify-end gap-2">
        <d.Close class="rounded-md border px-3 py-1.5 text-sm">Cancel</d.Close>
        <d.Close class="rounded-md bg-primary px-3 py-1.5 text-sm text-primary-foreground">
          Save
        </d.Close>
      </div>
    </d.Content>
  </Dialog>
</template>
