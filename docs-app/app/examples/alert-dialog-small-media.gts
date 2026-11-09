import { Bluetooth } from 'lucide'
import { AlertDialog, Button, Icon } from '@ember-joinery/ember'

<template>
  <AlertDialog as |d|>
    <Button @variant="outline" {{d.trigger}}>Show Dialog</Button>

    <d.Content @size="sm">
      <d.Header>
        <d.Media>
          <Icon @icon={{Bluetooth}} />
        </d.Media>
        <d.Title>Allow accessory to connect?</d.Title>
        <d.Description>
          Do you want to allow the USB accessory to connect to this device?
        </d.Description>
      </d.Header>
      <d.Footer>
        <d.Cancel>Don't allow</d.Cancel>
        <d.Action>Allow</d.Action>
      </d.Footer>
    </d.Content>
  </AlertDialog>
</template>
