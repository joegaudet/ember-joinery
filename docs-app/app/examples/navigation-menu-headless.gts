import { NavigationMenu } from '@ember-joinery/primitives/navigation-menu'

<template>
  {{!
    The headless navigation menu, styled with utility classes alone: its contents show in the
    viewport, which takes the open one's size, and the indicator follows the open trigger.
  }}
  <NavigationMenu class="relative" as |n|>
    <n.List class="m-0 flex list-none gap-1 p-0">
      <n.Item as |item|>
        <item.Trigger
          class="rounded border-0 bg-transparent px-3 py-2 text-sm text-gray-900 data-[state=open]:bg-gray-100"
        >
          Learn
        </item.Trigger>
        <item.Content class="absolute start-0 top-0 w-64 p-2">
          <n.Link href="#guides" class="block rounded p-2 text-sm text-gray-900 hover:bg-gray-100">
            Guides
          </n.Link>
          <n.Link
            href="#tutorials"
            class="block rounded p-2 text-sm text-gray-900 hover:bg-gray-100"
          >
            Tutorials
          </n.Link>
        </item.Content>
      </n.Item>
      <n.Item as |item|>
        <item.Trigger
          class="rounded border-0 bg-transparent px-3 py-2 text-sm text-gray-900 data-[state=open]:bg-gray-100"
        >
          Overview
        </item.Trigger>
        <item.Content class="absolute start-0 top-0 w-80 p-2">
          <n.Link href="#intro" class="block rounded p-2 text-sm text-gray-900 hover:bg-gray-100">
            Introduction
          </n.Link>
        </item.Content>
      </n.Item>
      <n.Item>
        <n.Link href="#github" class="block rounded px-3 py-2 text-sm text-gray-900">
          GitHub
        </n.Link>
      </n.Item>
    </n.List>
    <n.Indicator class="top-full flex h-2 items-end justify-center">
      <div class="size-2 rotate-45 bg-gray-300"></div>
    </n.Indicator>
    <div class="absolute start-0 top-full mt-2">
      <n.Viewport
        class="relative h-(--radix-navigation-menu-viewport-height) w-(--radix-navigation-menu-viewport-width) overflow-hidden rounded-md border border-gray-200 bg-white shadow-lg"
      />
    </div>
  </NavigationMenu>
</template>
