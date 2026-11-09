import { ContextMenu } from '@ember-joinery/primitives/context-menu'

<template>
  {{!
    The headless context menu, styled with utility classes alone: a right click (or a long
    press) in the area opens it at the pointer.
  }}
  <ContextMenu as |c|>
    <c.Trigger
      class="flex h-32 w-64 items-center justify-center rounded-md border-2 border-dashed border-gray-300 text-sm select-none"
    >
      Right click here
    </c.Trigger>
    <c.Content
      class="m-0 min-w-40 rounded-md border border-gray-200 bg-white p-1 text-sm text-gray-900 shadow-lg"
    >
      <c.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">Back</c.Item>
      <c.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">Reload</c.Item>
      <c.Separator class="my-1 h-px bg-gray-200" />
      <c.Sub as |s|>
        <s.Trigger class="rounded px-2 py-1 outline-none focus:bg-gray-100">More Tools ›</s.Trigger>
        <s.Content
          class="m-0 min-w-40 rounded-md border border-gray-200 bg-white p-1 text-sm text-gray-900 shadow-lg"
        >
          <c.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">Save Page...</c.Item>
        </s.Content>
      </c.Sub>
    </c.Content>
  </ContextMenu>
</template>
