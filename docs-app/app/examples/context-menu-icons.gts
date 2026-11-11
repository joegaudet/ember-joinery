import { ClipboardPaste, Copy, Scissors, Trash } from 'lucide'
import { ContextMenu, Icon } from '@ember-joinery/ember'

<template>
  <ContextMenu as |c|>
    <c.Trigger
      class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm"
    >
      <span class="hidden pointer-fine:inline-block">
        Right click here
      </span>
      <span class="hidden pointer-coarse:inline-block">
        Long press here
      </span>
    </c.Trigger>
    <c.Content>
      <c.Group>
        <c.Item>
          <Icon @icon={{Copy}} />
          Copy
        </c.Item>
        <c.Item>
          <Icon @icon={{Scissors}} />
          Cut
        </c.Item>
        <c.Item>
          <Icon @icon={{ClipboardPaste}} />
          Paste
        </c.Item>
      </c.Group>
      <c.Separator />
      <c.Group>
        <c.Item @variant="destructive">
          <Icon @icon={{Trash}} />
          Delete
        </c.Item>
      </c.Group>
    </c.Content>
  </ContextMenu>
</template>
