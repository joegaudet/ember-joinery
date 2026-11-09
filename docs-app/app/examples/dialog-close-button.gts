import { Button, Dialog, Input, Label } from '@ember-joinery/ember'

<template>
  <Dialog as |d|>
    <Button @variant="outline" {{d.trigger}}>Share</Button>
    <d.Content class="sm:max-w-md">
      <d.Header>
        <d.Title>Share link</d.Title>
        <d.Description>
          Anyone who has this link will be able to view this.
        </d.Description>
      </d.Header>
      <div class="flex items-center gap-2">
        <div class="grid flex-1 gap-2">
          <Label for="link" class="sr-only">
            Link
          </Label>
          <Input id="link" @defaultValue="https://ui.shadcn.com/docs/installation" readonly />
        </div>
      </div>
      <d.Footer class="sm:justify-start">
        <Button type="button" {{d.close}}>Close</Button>
      </d.Footer>
    </d.Content>
  </Dialog>
</template>
