import { Trash2 } from 'lucide'
import { AlertDialog, Button, Icon } from '@ember-joinery/ember'

<template>
  <AlertDialog as |d|>
    <Button @variant="destructive" {{d.trigger}}>Delete Chat</Button>
    <d.Content @size="sm">
      <d.Header>
        <d.Media
          class="bg-destructive/10 text-destructive dark:bg-destructive/20 dark:text-destructive"
        >
          <Icon @icon={{Trash2}} />
        </d.Media>
        <d.Title>Delete chat?</d.Title>
        <d.Description>
          This will permanently delete this chat conversation. View
          <a href="#">Settings</a>
          delete any memories saved during this chat.
        </d.Description>
      </d.Header>
      <d.Footer>
        <d.Cancel @variant="outline">Cancel</d.Cancel>
        <d.Action @variant="destructive">Delete</d.Action>
      </d.Footer>
    </d.Content>
  </AlertDialog>
</template>
