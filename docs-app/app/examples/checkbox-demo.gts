import {
  Checkbox,
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldTitle,
  Label,
} from '@ember-joinery/ember'

<template>
  {{!
    The last checkbox names itself by its card's title with aria-labelledby, which upstream's
    leaves off: axe can't read a name through the field's role="group" inside the label,
    though browsers do, so the audit would fail without it.
  }}
  <FieldGroup class="max-w-sm">
    <Field @orientation="horizontal">
      <Checkbox id="terms-checkbox" name="terms-checkbox" />
      <Label for="terms-checkbox">Accept terms and conditions</Label>
    </Field>
    <Field @orientation="horizontal">
      <Checkbox id="terms-checkbox-2" name="terms-checkbox-2" @defaultChecked={{true}} />
      <FieldContent>
        <FieldLabel for="terms-checkbox-2">
          Accept terms and conditions
        </FieldLabel>
        <FieldDescription>
          By clicking this checkbox, you agree to the terms.
        </FieldDescription>
      </FieldContent>
    </Field>
    <Field @orientation="horizontal" @disabled={{true}}>
      <Checkbox id="toggle-checkbox" name="toggle-checkbox" @disabled={{true}} />
      <FieldLabel for="toggle-checkbox">Enable notifications</FieldLabel>
    </Field>
    <FieldLabel>
      <Field @orientation="horizontal">
        <Checkbox
          id="toggle-checkbox-2"
          name="toggle-checkbox-2"
          aria-labelledby="toggle-checkbox-2-title"
        />
        <FieldContent>
          <FieldTitle id="toggle-checkbox-2-title">Enable notifications</FieldTitle>
          <FieldDescription>
            You can enable or disable notifications at any time.
          </FieldDescription>
        </FieldContent>
      </Field>
    </FieldLabel>
  </FieldGroup>
</template>
