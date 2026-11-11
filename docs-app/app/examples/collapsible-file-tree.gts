import type { TOC } from '@ember/component/template-only'
import { ChevronRight, File, Folder } from 'lucide'
import { Button, Card, Collapsible, Icon, Tabs } from '@ember-joinery/ember'

type FileTreeItem = { name: string } | { name: string; items: FileTreeItem[] }

const fileTree: FileTreeItem[] = [
  {
    name: 'components',
    items: [
      {
        name: 'ui',
        items: [
          { name: 'button.tsx' },
          { name: 'card.tsx' },
          { name: 'dialog.tsx' },
          { name: 'input.tsx' },
          { name: 'select.tsx' },
          { name: 'table.tsx' },
        ],
      },
      { name: 'login-form.tsx' },
      { name: 'register-form.tsx' },
    ],
  },
  {
    name: 'lib',
    items: [{ name: 'utils.ts' }, { name: 'cn.ts' }, { name: 'api.ts' }],
  },
  {
    name: 'hooks',
    items: [
      { name: 'use-media-query.ts' },
      { name: 'use-debounce.ts' },
      { name: 'use-local-storage.ts' },
    ],
  },
  {
    name: 'types',
    items: [{ name: 'index.d.ts' }, { name: 'api.d.ts' }],
  },
  {
    name: 'public',
    items: [{ name: 'favicon.ico' }, { name: 'logo.svg' }, { name: 'images' }],
  },
  { name: 'app.tsx' },
  { name: 'layout.tsx' },
  { name: 'globals.css' },
  { name: 'package.json' },
  { name: 'tsconfig.json' },
  { name: 'README.md' },
  { name: '.gitignore' },
]

/** A folder's items, or none for a file: upstream's `"items" in fileItem`. */
const itemsOf = (fileItem: FileTreeItem) => ('items' in fileItem ? fileItem.items : undefined)

// Upstream's renderItem, which calls itself for a folder's items: here a component that renders
// itself. A folder is a collapsible, its trigger a Button (upstream's asChild); a file is a link
// Button.
const FileTreeNode: TOC<{ Args: { fileItem: FileTreeItem } }> = <template>
  {{#let (itemsOf @fileItem) as |items|}}
    {{#if items}}
      <Collapsible as |c|>
        <Button
          @variant="ghost"
          @size="sm"
          class="group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
          {{c.trigger}}
        >
          <Icon
            @icon={{ChevronRight}}
            class="transition-transform group-data-[state=open]:rotate-90"
          />
          <Icon @icon={{Folder}} />
          {{@fileItem.name}}
        </Button>
        <c.Content class="mt-1 ml-5 style-lyra:ml-4">
          <div class="flex flex-col gap-1">
            {{#each items as |child|}}
              <FileTreeNode @fileItem={{child}} />
            {{/each}}
          </div>
        </c.Content>
      </Collapsible>
    {{else}}
      <Button @variant="link" @size="sm" class="w-full justify-start gap-2 text-foreground">
        <Icon @icon={{File}} />
        <span>{{@fileItem.name}}</span>
      </Button>
    {{/if}}
  {{/let}}
</template>

<template>
  <Card class="mx-auto w-full max-w-[16rem] gap-2" @size="sm" as |card|>
    <card.Header>
      <Tabs @defaultValue="explorer" as |t|>
        <t.List class="w-full">
          <t.Trigger @value="explorer">Explorer</t.Trigger>
          <t.Trigger @value="settings">Outline</t.Trigger>
        </t.List>
      </Tabs>
    </card.Header>
    <card.Content>
      <div class="flex flex-col gap-1">
        {{#each fileTree as |item|}}
          <FileTreeNode @fileItem={{item}} />
        {{/each}}
      </div>
    </card.Content>
  </Card>
</template>
