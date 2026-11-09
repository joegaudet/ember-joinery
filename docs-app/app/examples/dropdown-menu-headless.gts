import { EllipsisVertical } from 'lucide'
import { Icon } from '@ember-joinery/ember'
import { Menu } from '@ember-joinery/primitives/dropdown-menu'

<template>
  {{!
    ember-primitives' Menu demo, on the headless dropdown menu (exported as Menu too) and styled
    with utility classes alone: its Content yields Item, LinkItem and Separator, and its root
    takes ember-primitives' positioning arguments.
  }}
  <Menu @offsetOptions={{8}} as |m|>
    <m.Trigger
      class="rounded-full border-0 bg-white p-2.5 text-gray-900 shadow-md"
      aria-label="Options"
    >
      <Icon @icon={{EllipsisVertical}} @size={{15}} />
    </m.Trigger>
    <m.Content
      class="m-0 flex min-w-44 flex-col rounded-md border-0 bg-white py-2 text-sm text-gray-900 shadow-lg"
      as |c|
    >
      <c.Item class="px-3 py-1 outline-none focus:bg-gray-100">Item 1</c.Item>
      <c.Item class="px-3 py-1 outline-none focus:bg-gray-100">Item 2</c.Item>
      <c.Separator class="my-1 border-b border-gray-200" />
      <c.LinkItem
        @href="/"
        class="px-3 py-1 text-gray-900 no-underline outline-none focus:bg-gray-100"
      >
        Item 3
      </c.LinkItem>
    </m.Content>
  </Menu>
</template>
