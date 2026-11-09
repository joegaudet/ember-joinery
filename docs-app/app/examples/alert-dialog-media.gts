import { CircleFadingPlus } from 'lucide'
import { AlertDialog, Button, Icon } from '@ember-joinery/ember'

<template>
  <AlertDialog as |d|>
    <Button @variant="outline" {{d.trigger}}>Share Project</Button>
    <d.Content>
      <d.Header>
        <d.Media>
          <Icon @icon={{CircleFadingPlus}} />
        </d.Media>
        <d.Title>Share this project?</d.Title>
        <d.Description>
          Anyone with the link will be able to view and edit this project.
        </d.Description>
      </d.Header>
      <d.Footer>
        <d.Cancel>Cancel</d.Cancel>
        <d.Action>Share</d.Action>
      </d.Footer>
    </d.Content>
  </AlertDialog>
</template>
