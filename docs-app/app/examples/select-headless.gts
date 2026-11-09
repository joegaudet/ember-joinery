import { Select } from '@ember-joinery/primitives/select'

<template>
  {{!
    The headless select, styled here with utility classes alone: below its trigger
    (`@position="popper"`), with its own check marks, and named by a label of its own.
  }}
  <div class="flex flex-col gap-1.5">
    <label id="headless-fruit-label" class="text-sm font-medium">Fruit</label>
    <Select @defaultValue="banana" as |s|>
      <s.Trigger
        aria-labelledby="headless-fruit-label"
        class="flex w-48 items-center justify-between rounded-md border px-3 py-1.5 text-sm"
      >
        <s.Value @placeholder="Pick a fruit" />
        <s.Icon class="text-xs" />
      </s.Trigger>
      <s.Content
        @position="popper"
        @sideOffset={{4}}
        class="m-0 min-w-48 rounded-md border bg-white p-1 text-sm shadow"
      >
        <s.Viewport>
          <s.Group>
            <s.Label class="px-2 py-1 text-xs text-gray-500">Fruits</s.Label>
            <s.Item
              @value="apple"
              class="flex items-center justify-between rounded px-2 py-1 outline-none data-highlighted:bg-gray-100"
              as |item|
            >
              <item.ItemText>Apple</item.ItemText>
              <item.ItemIndicator>✓</item.ItemIndicator>
            </s.Item>
            <s.Item
              @value="banana"
              class="flex items-center justify-between rounded px-2 py-1 outline-none data-highlighted:bg-gray-100"
              as |item|
            >
              <item.ItemText>Banana</item.ItemText>
              <item.ItemIndicator>✓</item.ItemIndicator>
            </s.Item>
            <s.Item
              @value="cherry"
              @disabled={{true}}
              class="flex items-center justify-between rounded px-2 py-1 text-gray-400 outline-none"
              as |item|
            >
              <item.ItemText>Cherry</item.ItemText>
            </s.Item>
          </s.Group>
        </s.Viewport>
      </s.Content>
    </Select>
  </div>
</template>
