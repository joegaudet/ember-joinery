import {
  Field,
  FieldDescription,
  FieldLabel,
  FieldLegend,
  FieldSet,
  RadioGroup,
} from '@ember-joinery/ember'

<template>
  <FieldSet class="w-full max-w-xs">
    <FieldLegend @variant="label">Notification Preferences</FieldLegend>
    <FieldDescription>
      Choose how you want to receive notifications.
    </FieldDescription>
    <RadioGroup @defaultValue="email" as |group|>
      <Field @orientation="horizontal" @invalid={{true}}>
        <group.Item @value="email" id="invalid-email" aria-invalid="true" />
        <FieldLabel for="invalid-email" class="font-normal">
          Email only
        </FieldLabel>
      </Field>
      <Field @orientation="horizontal" @invalid={{true}}>
        <group.Item @value="sms" id="invalid-sms" aria-invalid="true" />
        <FieldLabel for="invalid-sms" class="font-normal">
          SMS only
        </FieldLabel>
      </Field>
      <Field @orientation="horizontal" @invalid={{true}}>
        <group.Item @value="both" id="invalid-both" aria-invalid="true" />
        <FieldLabel for="invalid-both" class="font-normal">
          Both Email &amp; SMS
        </FieldLabel>
      </Field>
    </RadioGroup>
  </FieldSet>
</template>
