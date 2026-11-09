import { Alert, Button } from '@ember-joinery/ember'

<template>
  <Alert class="max-w-md" as |a|>
    <a.Title>Dark mode is now available</a.Title>
    <a.Description>
      Enable it under your profile settings to get started.
    </a.Description>
    <a.Action>
      <Button @size="xs" @variant="default">
        Enable
      </Button>
    </a.Action>
  </Alert>
</template>
