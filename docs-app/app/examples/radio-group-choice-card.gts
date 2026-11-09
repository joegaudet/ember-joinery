import {
  Field,
  FieldContent,
  FieldDescription,
  FieldLabel,
  FieldTitle,
  RadioGroup,
} from '@ember-joinery/ember'

<template>
  {{!
    Each radio names itself by its card's title with aria-labelledby, which upstream's leave
    off: axe can't read a name through the field's role="group" inside the label, though
    browsers do, so the audit would fail without it.
  }}
  <RadioGroup @defaultValue="plus" class="max-w-sm" as |group|>
    <FieldLabel for="plus-plan">
      <Field @orientation="horizontal">
        <FieldContent>
          <FieldTitle id="plus-plan-title">Plus</FieldTitle>
          <FieldDescription>
            For individuals and small teams.
          </FieldDescription>
        </FieldContent>
        <group.Item @value="plus" id="plus-plan" aria-labelledby="plus-plan-title" />
      </Field>
    </FieldLabel>
    <FieldLabel for="pro-plan">
      <Field @orientation="horizontal">
        <FieldContent>
          <FieldTitle id="pro-plan-title">Pro</FieldTitle>
          <FieldDescription>For growing businesses.</FieldDescription>
        </FieldContent>
        <group.Item @value="pro" id="pro-plan" aria-labelledby="pro-plan-title" />
      </Field>
    </FieldLabel>
    <FieldLabel for="enterprise-plan">
      <Field @orientation="horizontal">
        <FieldContent>
          <FieldTitle id="enterprise-plan-title">Enterprise</FieldTitle>
          <FieldDescription>
            For large teams and enterprises.
          </FieldDescription>
        </FieldContent>
        <group.Item
          @value="enterprise"
          id="enterprise-plan"
          aria-labelledby="enterprise-plan-title"
        />
      </Field>
    </FieldLabel>
  </RadioGroup>
</template>
