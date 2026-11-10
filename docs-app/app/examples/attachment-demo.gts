import { FileCode, X } from 'lucide'
import { Attachment, AttachmentGroup, Icon, Spinner } from '@ember-joinery/ember'

const images = [
  {
    name: 'workspace.png',
    meta: 'PNG · 820 KB',
    src: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80',
    alt: 'Workspace',
  },
  {
    name: 'desk-reference.jpg',
    meta: 'JPG · 1.1 MB',
    src: 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=900&auto=format&fit=crop&q=80',
    alt: 'Desk',
  },
  {
    name: 'office-reference.jpg',
    meta: 'JPG · 940 KB',
    src: 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=900&auto=format&fit=crop&q=80',
    alt: 'Office',
  },
]

<template>
  <div class="mx-auto flex w-full max-w-sm flex-col gap-3 py-12">
    <AttachmentGroup>
      {{#each images as |image|}}
        <Attachment @orientation="vertical" as |at|>
          <at.Media @variant="image">
            <img src={{image.src}} alt={{image.alt}} />
          </at.Media>
          <at.Content>
            <at.Title>{{image.name}}</at.Title>
            <at.Description>{{image.meta}}</at.Description>
          </at.Content>
        </Attachment>
      {{/each}}
    </AttachmentGroup>
    <Attachment @state="uploading" class="w-full" as |at|>
      <at.Media>
        <Spinner />
      </at.Media>
      <at.Content>
        <at.Title>sales-dashboard.pdf</at.Title>
        <at.Description>Uploading · 64%</at.Description>
      </at.Content>
      <at.Actions>
        <at.Action aria-label="Cancel upload">
          <Icon @icon={{X}} />
        </at.Action>
      </at.Actions>
    </Attachment>
    <Attachment class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{FileCode}} />
      </at.Media>
      <at.Content>
        <at.Title>message-renderer.tsx</at.Title>
        <at.Description>TypeScript · 12 KB</at.Description>
      </at.Content>
      <at.Actions>
        <at.Action aria-label="Remove message-renderer.tsx">
          <Icon @icon={{X}} />
        </at.Action>
      </at.Actions>
    </Attachment>
  </div>
</template>
