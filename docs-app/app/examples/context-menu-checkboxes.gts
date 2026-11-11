import { ContextMenu } from '@ember-joinery/ember'

// Upstream passes `defaultChecked`, which Radix's CheckboxItem doesn't take (its state is only
// ever `checked`), so on ui.shadcn.com all three items open unchecked and don't toggle. A
// CheckboxItem here takes no `@defaultChecked` either, so these are plain, as upstream's render.
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
        <c.CheckboxItem>
          Show Bookmarks Bar
        </c.CheckboxItem>
        <c.CheckboxItem>Show Full URLs</c.CheckboxItem>
        <c.CheckboxItem>
          Show Developer Tools
        </c.CheckboxItem>
      </c.Group>
    </c.Content>
  </ContextMenu>
</template>
