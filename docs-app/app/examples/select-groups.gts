import { Select } from '@ember-joinery/ember'

<template>
  {{! Named with aria-label: a combobox isn't named by its text, and upstream's has no label. }}
  <Select as |s|>
    <s.Trigger class="w-full max-w-48" aria-label="Food">
      <s.Value @placeholder="Select a fruit" />
    </s.Trigger>
    <s.Content>
      <s.Group>
        <s.Label>Fruits</s.Label>
        <s.Item @value="apple">Apple</s.Item>
        <s.Item @value="banana">Banana</s.Item>
        <s.Item @value="blueberry">Blueberry</s.Item>
      </s.Group>
      <s.Separator />
      <s.Group>
        <s.Label>Vegetables</s.Label>
        <s.Item @value="carrot">Carrot</s.Item>
        <s.Item @value="broccoli">Broccoli</s.Item>
        <s.Item @value="spinach">Spinach</s.Item>
      </s.Group>
    </s.Content>
  </Select>
</template>
