import { Field, FieldDescription, FieldLabel, Select } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's FieldLabel names nothing; this one names the trigger (for and id), as a
    combobox must be named.
  }}
  <Field class="w-full max-w-xs">
    <FieldLabel for="field-select-department">Department</FieldLabel>
    <Select as |s|>
      <s.Trigger id="field-select-department">
        <s.Value @placeholder="Choose department" />
      </s.Trigger>
      <s.Content>
        <s.Group>
          <s.Item @value="engineering">Engineering</s.Item>
          <s.Item @value="design">Design</s.Item>
          <s.Item @value="marketing">Marketing</s.Item>
          <s.Item @value="sales">Sales</s.Item>
          <s.Item @value="support">Customer Support</s.Item>
          <s.Item @value="hr">Human Resources</s.Item>
          <s.Item @value="finance">Finance</s.Item>
          <s.Item @value="operations">Operations</s.Item>
        </s.Group>
      </s.Content>
    </Select>
    <FieldDescription>
      Select your department or area of work.
    </FieldDescription>
  </Field>
</template>
