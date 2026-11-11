import { X } from 'lucide'
import { concat } from '@ember/helper'
import { Attachment, AttachmentGroup, Icon } from '@ember-joinery/ember'

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
  <div class="mx-auto w-full max-w-sm py-12">
    <AttachmentGroup class="w-full">
      {{#each images as |image|}}
        <Attachment @orientation="vertical" as |at|>
          <at.Media @variant="image">
            <img src={{image.src}} alt={{image.alt}} />
          </at.Media>
          <at.Content>
            <at.Title>{{image.name}}</at.Title>
            <at.Description>{{image.meta}}</at.Description>
          </at.Content>
          <at.Actions>
            <at.Action aria-label={{concat "Remove " image.name}}>
              <Icon @icon={{X}} />
            </at.Action>
          </at.Actions>
          <at.Trigger
            @as="a"
            href={{image.src}}
            target="_blank"
            rel="noreferrer"
            aria-label={{concat "Open " image.name}}
          />
        </Attachment>
      {{/each}}
    </AttachmentGroup>
  </div>
</template>
