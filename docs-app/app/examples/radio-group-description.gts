import { Field, FieldContent, FieldDescription, FieldLabel, RadioGroup } from '@ember-joinery/ember'

<template>
  <RadioGroup @defaultValue="comfortable" class="w-fit" as |group|>
    <Field @orientation="horizontal">
      <group.Item @value="default" id="desc-r1" />
      <FieldContent>
        <FieldLabel for="desc-r1">Default</FieldLabel>
        <FieldDescription>
          Standard spacing for most use cases.
        </FieldDescription>
      </FieldContent>
    </Field>
    <Field @orientation="horizontal">
      <group.Item @value="comfortable" id="desc-r2" />
      <FieldContent>
        <FieldLabel for="desc-r2">Comfortable</FieldLabel>
        <FieldDescription>More space between elements.</FieldDescription>
      </FieldContent>
    </Field>
    <Field @orientation="horizontal">
      <group.Item @value="compact" id="desc-r3" />
      <FieldContent>
        <FieldLabel for="desc-r3">Compact</FieldLabel>
        <FieldDescription>
          Minimal spacing for dense layouts.
        </FieldDescription>
      </FieldContent>
    </Field>
  </RadioGroup>
</template>
