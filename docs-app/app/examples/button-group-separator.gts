import { Button, ButtonGroup } from '@ember-joinery/ember'

<template>
  <ButtonGroup as |g|>
    <Button @variant="secondary" @size="sm">
      Copy
    </Button>
    <g.Separator />
    <Button @variant="secondary" @size="sm">
      Paste
    </Button>
  </ButtonGroup>
</template>
