import { Button, Spinner } from '@ember-joinery/ember'

<template>
  <div class="flex flex-col items-center gap-4">
    <Button disabled @size="sm">
      <Spinner data-icon="inline-start" />
      Loading...
    </Button>
    <Button @variant="outline" disabled @size="sm">
      <Spinner data-icon="inline-start" />
      Please wait
    </Button>
    <Button @variant="secondary" disabled @size="sm">
      <Spinner data-icon="inline-start" />
      Processing
    </Button>
  </div>
</template>
