import {
  Button,
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSet,
  Input,
} from '@ember-joinery/ember'

<template>
  <div class="w-full max-w-lg">
    <form>
      <FieldSet>
        <FieldLegend>Profile</FieldLegend>
        <FieldDescription>Fill in your profile information.</FieldDescription>
        <FieldGroup>
          <Field @orientation="responsive">
            <FieldContent>
              <FieldLabel for="name">Name</FieldLabel>
              <FieldDescription>
                Provide your full name for identification
              </FieldDescription>
            </FieldContent>
            <Input id="name" placeholder="Evil Rabbit" required />
          </Field>
          <Field @orientation="responsive">
            <Button type="submit">Submit</Button>
            <Button type="button" @variant="outline">
              Cancel
            </Button>
          </Field>
        </FieldGroup>
      </FieldSet>
    </form>
  </div>
</template>
