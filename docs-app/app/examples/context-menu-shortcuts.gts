import { ContextMenu } from '@ember-joinery/ember'

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
          Back
          <c.Shortcut>⌘[</c.Shortcut>
        </c.Item>
        <c.Item @disabled={{true}}>
          Forward
          <c.Shortcut>⌘]</c.Shortcut>
        </c.Item>
        <c.Item>
          Reload
          <c.Shortcut>⌘R</c.Shortcut>
        </c.Item>
      </c.Group>
      <c.Separator />
      <c.Group>
        <c.Item>
          Save
          <c.Shortcut>⌘S</c.Shortcut>
        </c.Item>
        <c.Item>
          Save As...
          <c.Shortcut>⇧⌘S</c.Shortcut>
        </c.Item>
      </c.Group>
    </c.Content>
  </ContextMenu>
</template>
