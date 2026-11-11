import { Button, Tooltip } from '@ember-joinery/ember'

<template>
  <Tooltip as |t|>
    <Button @variant="outline" {{t.trigger}}>Hover</Button>
    <t.Content>
      <p>Add to library</p>
    </t.Content>
  </Tooltip>
</template>
