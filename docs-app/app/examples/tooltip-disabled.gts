import { Button, Tooltip } from '@ember-joinery/ember'

<template>
  <Tooltip as |t|>
    <span class="inline-block w-fit" {{t.trigger}}>
      <Button @variant="outline" disabled>
        Disabled
      </Button>
    </span>
    <t.Content>
      <p>This feature is currently unavailable</p>
    </t.Content>
  </Tooltip>
</template>
