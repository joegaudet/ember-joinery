import { Field, FieldError, FieldLabel, Select } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's FieldLabel names nothing; this one names the trigger (for and id), as a
    combobox must be named.
  }}
  <Field @invalid={{true}} class="w-full max-w-48">
    <FieldLabel for="select-invalid-fruit">Fruit</FieldLabel>
    <Select as |s|>
      <s.Trigger id="select-invalid-fruit" aria-invalid="true">
        <s.Value @placeholder="Select a fruit" />
      </s.Trigger>
      <s.Content>
        <s.Group>
          <s.Item @value="apple">Apple</s.Item>
          <s.Item @value="banana">Banana</s.Item>
          <s.Item @value="blueberry">Blueberry</s.Item>
        </s.Group>
      </s.Content>
    </Select>
    <FieldError>Please select a fruit.</FieldError>
  </Field>
</template>
