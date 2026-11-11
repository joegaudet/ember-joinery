import { AlertDialog, Button } from '@ember-joinery/ember'

<template>
  <AlertDialog as |d|>
    <Button @variant="outline" {{d.trigger}}>Show Dialog</Button>
    <d.Content>
      <d.Header>
        <d.Title>Are you absolutely sure?</d.Title>
        <d.Description>
          This action cannot be undone. This will permanently delete your account from our servers.
        </d.Description>
      </d.Header>
      <d.Footer>
        <d.Cancel>Cancel</d.Cancel>
        <d.Action>Continue</d.Action>
      </d.Footer>
    </d.Content>
  </AlertDialog>
</template>
