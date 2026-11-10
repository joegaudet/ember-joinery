import { Menubar } from '@ember-joinery/primitives/menubar'

<template>
  {{!
    The headless menubar, styled with utility classes alone: the arrow keys move between its
    triggers, and while a menu is open they (and the pointer) move to the others.
  }}
  <Menubar class="flex gap-1 rounded-md border border-gray-200 bg-white p-1" as |bar|>
    <bar.Menu as |m|>
      <m.Trigger
        class="rounded border-0 bg-transparent px-2 py-1 text-sm text-gray-900 data-[state=open]:bg-gray-100"
      >
        File
      </m.Trigger>
      <m.Content
        class="m-0 min-w-40 rounded-md border border-gray-200 bg-white p-1 text-sm text-gray-900 shadow-lg"
      >
        <m.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">New Tab</m.Item>
        <m.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">New Window</m.Item>
        <m.Separator class="my-1 h-px bg-gray-200" />
        <m.Sub as |s|>
          <s.Trigger class="rounded px-2 py-1 outline-none focus:bg-gray-100">Share ›</s.Trigger>
          <s.Content
            class="m-0 min-w-40 rounded-md border border-gray-200 bg-white p-1 text-sm text-gray-900 shadow-lg"
          >
            <m.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">Email link</m.Item>
          </s.Content>
        </m.Sub>
      </m.Content>
    </bar.Menu>
    <bar.Menu as |m|>
      <m.Trigger
        class="rounded border-0 bg-transparent px-2 py-1 text-sm text-gray-900 data-[state=open]:bg-gray-100"
      >
        Edit
      </m.Trigger>
      <m.Content
        class="m-0 min-w-40 rounded-md border border-gray-200 bg-white p-1 text-sm text-gray-900 shadow-lg"
      >
        <m.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">Undo</m.Item>
        <m.Item class="rounded px-2 py-1 outline-none focus:bg-gray-100">Redo</m.Item>
      </m.Content>
    </bar.Menu>
  </Menubar>
</template>
