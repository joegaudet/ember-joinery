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
        <c.Label>File</c.Label>
        <c.Item>
          New File
          <c.Shortcut>⌘N</c.Shortcut>
        </c.Item>
        <c.Item>
          Open File
          <c.Shortcut>⌘O</c.Shortcut>
        </c.Item>
        <c.Item>
          Save
          <c.Shortcut>⌘S</c.Shortcut>
        </c.Item>
      </c.Group>
      <c.Separator />
      <c.Group>
        <c.Label>Edit</c.Label>
        <c.Item>
          Undo
          <c.Shortcut>⌘Z</c.Shortcut>
        </c.Item>
        <c.Item>
          Redo
          <c.Shortcut>⇧⌘Z</c.Shortcut>
        </c.Item>
      </c.Group>
      <c.Separator />
      <c.Group>
        <c.Item>
          Cut
          <c.Shortcut>⌘X</c.Shortcut>
        </c.Item>
        <c.Item>
          Copy
          <c.Shortcut>⌘C</c.Shortcut>
        </c.Item>
        <c.Item>
          Paste
          <c.Shortcut>⌘V</c.Shortcut>
        </c.Item>
      </c.Group>
      <c.Separator />
      <c.Group>
        <c.Item @variant="destructive">
          Delete
          <c.Shortcut>⌫</c.Shortcut>
        </c.Item>
      </c.Group>
    </c.Content>
  </ContextMenu>
</template>
