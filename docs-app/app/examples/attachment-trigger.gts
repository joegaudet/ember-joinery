import { Copy, FileSearch, X } from 'lucide'
import { Attachment, Dialog, Icon } from '@ember-joinery/ember'

<template>
  <div class="mx-auto w-full max-w-sm py-12">
    <Dialog as |d|>
      <Attachment class="w-full" as |at|>
        <at.Media>
          <Icon @icon={{FileSearch}} />
        </at.Media>
        <at.Content>
          <at.Title>research-summary.pdf</at.Title>
          <at.Description>Open preview dialog</at.Description>
        </at.Content>
        <at.Actions>
          <at.Action aria-label="Copy link">
            <Icon @icon={{Copy}} />
          </at.Action>
          <at.Action aria-label="Remove research-summary.pdf">
            <Icon @icon={{X}} />
          </at.Action>
        </at.Actions>
        <at.Trigger aria-label="Preview research-summary.pdf" {{d.trigger}} />
      </Attachment>
      <d.Content class="sm:max-w-md">
        <d.Header>
          <d.Title>research-summary.pdf</d.Title>
          <d.Description>
            The attachment trigger fills the card and opens the dialog, while the actions stay
            independently clickable above it.
          </d.Description>
        </d.Header>
      </d.Content>
    </Dialog>
  </div>
</template>
