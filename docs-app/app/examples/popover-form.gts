import { Button, Field, FieldGroup, FieldLabel, Input, Popover } from '@ember-joinery/ember'

<template>
  {{! Named popover, not p: a block param named p would turn a <p> into a call to it. }}
  <Popover as |popover|>
    <Button @variant="outline" {{popover.trigger}}>Open Popover</Button>
    <popover.Content class="w-64" @align="start">
      <popover.Header>
        <popover.Title>Dimensions</popover.Title>
        <popover.Description>
          Set the dimensions for the layer.
        </popover.Description>
      </popover.Header>
      <FieldGroup class="gap-4">
        <Field @orientation="horizontal">
          <FieldLabel for="width" class="w-1/2">
            Width
          </FieldLabel>
          <Input id="width" @defaultValue="100%" />
        </Field>
        <Field @orientation="horizontal">
          <FieldLabel for="height" class="w-1/2">
            Height
          </FieldLabel>
          <Input id="height" @defaultValue="25px" />
        </Field>
      </FieldGroup>
    </popover.Content>
  </Popover>
</template>
