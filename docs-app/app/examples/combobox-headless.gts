import { Combobox } from '@ember-joinery/primitives/combobox'

const fruits = ['Apple', 'Banana', 'Blueberry', 'Cherry', 'Grapes', 'Pineapple']

<template>
  {{!
    The headless combobox, styled here with utility classes alone: an input that filters the
    fruits, a list below it, and the highlight (data-highlighted) while focus stays in the input.
  }}
  <div class="flex flex-col gap-1.5">
    <label for="headless-fruit" class="text-sm font-medium">Fruit</label>
    <Combobox @items={{fruits}} @autoHighlight={{true}} as |c|>
      <c.Input id="headless-fruit" class="w-56 rounded-md border px-3 py-1.5 text-sm" />
      <c.Content
        @sideOffset={{4}}
        @align="start"
        class="m-0 w-56 rounded-md border bg-white p-1 text-sm shadow"
      >
        <c.Empty class="px-2 py-1 text-gray-500">No fruit matches.</c.Empty>
        <c.List as |fruit|>
          <c.Item
            @value={{fruit}}
            class="flex items-center justify-between rounded px-2 py-1 data-highlighted:bg-gray-100"
            as |item|
          >
            {{fruit}}
            <item.ItemIndicator>✓</item.ItemIndicator>
          </c.Item>
        </c.List>
      </c.Content>
    </Combobox>
  </div>
</template>
