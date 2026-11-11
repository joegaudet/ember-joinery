import { Select } from '@ember-joinery/ember'

<template>
  {{! Named with aria-label: a combobox isn't named by its text, and upstream's has no label. }}
  <Select as |s|>
    <s.Trigger class="w-full max-w-48" aria-label="Fruit">
      <s.Value @placeholder="Select a fruit" />
    </s.Trigger>
    <s.Content>
      <s.Group>
        <s.Label>Fruits</s.Label>
        <s.Item @value="apple">Apple</s.Item>
        <s.Item @value="banana">Banana</s.Item>
        <s.Item @value="blueberry">Blueberry</s.Item>
        <s.Item @value="grapes">Grapes</s.Item>
        <s.Item @value="pineapple">Pineapple</s.Item>
      </s.Group>
    </s.Content>
  </Select>
</template>
