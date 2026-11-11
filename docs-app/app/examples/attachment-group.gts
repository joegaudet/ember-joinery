import { FileCode, FileText, Table, X, type IconNode } from 'lucide'
import { concat } from '@ember/helper'
import { Attachment, AttachmentGroup, Icon } from '@ember-joinery/ember'

interface Item {
  name: string
  meta: string
  icon?: IconNode
  src?: string
}

const items: Item[] = [
  { name: 'briefing-notes.pdf', meta: 'PDF · 1.4 MB', icon: FileText },
  {
    name: 'workspace.png',
    meta: 'PNG · 820 KB',
    src: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80',
  },
  { name: 'customers.csv', meta: 'CSV · 18 KB', icon: Table },
  { name: 'renderer.tsx', meta: 'TSX · 12 KB', icon: FileCode },
]

<template>
  <div class="mx-auto w-full max-w-sm py-12">
    <AttachmentGroup class="w-full">
      {{#each items as |item|}}
        <Attachment class="w-64" as |at|>
          {{#if item.src}}
            <at.Media @variant="image">
              <img src={{item.src}} alt={{item.name}} />
            </at.Media>
          {{else if item.icon}}
            <at.Media>
              <Icon @icon={{item.icon}} />
            </at.Media>
          {{/if}}
          <at.Content>
            <at.Title>{{item.name}}</at.Title>
            <at.Description>{{item.meta}}</at.Description>
          </at.Content>
          <at.Actions>
            <at.Action aria-label={{concat "Remove " item.name}}>
              <Icon @icon={{X}} />
            </at.Action>
          </at.Actions>
        </Attachment>
      {{/each}}
    </AttachmentGroup>
  </div>
</template>
