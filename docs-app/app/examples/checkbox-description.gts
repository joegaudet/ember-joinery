import {
  Checkbox,
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
} from '@ember-joinery/ember'

<template>
  <FieldGroup class="mx-auto w-72">
    <Field @orientation="horizontal">
      <Checkbox id="terms-checkbox-desc" name="terms-checkbox-desc" @defaultChecked={{true}} />
      <FieldContent>
        <FieldLabel for="terms-checkbox-desc">
          Accept terms and conditions
        </FieldLabel>
        <FieldDescription>
          By clicking this checkbox, you agree to the terms and conditions.
        </FieldDescription>
      </FieldContent>
    </Field>
  </FieldGroup>
</template>
