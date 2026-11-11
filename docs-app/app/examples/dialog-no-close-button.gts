import { Button, Dialog } from '@ember-joinery/ember'

<template>
  <Dialog as |d|>
    <Button @variant="outline" {{d.trigger}}>No Close Button</Button>
    <d.Content @showCloseButton={{false}}>
      <d.Header>
        <d.Title>No Close Button</d.Title>
        <d.Description>
          This dialog doesn't have a close button in the top-right corner.
        </d.Description>
      </d.Header>
    </d.Content>
  </Dialog>
</template>
