import { Button, Spinner } from '@ember-joinery/ember'

<template>
  <div class="flex gap-2">
    <Button @variant="outline" disabled>
      <Spinner data-icon="inline-start" />
      Generating
    </Button>
    <Button @variant="secondary" disabled>
      Downloading
      <Spinner data-icon="inline-start" />
    </Button>
  </div>
</template>
