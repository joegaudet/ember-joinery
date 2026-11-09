import { Button, Empty, Spinner } from '@ember-joinery/ember'

<template>
  <Empty class="w-full" as |e|>
    <e.Header>
      <e.Media @variant="icon">
        <Spinner />
      </e.Media>
      <e.Title>Processing your request</e.Title>
      <e.Description>
        Please wait while we process your request. Do not refresh the page.
      </e.Description>
    </e.Header>
    <e.Content>
      <Button @variant="outline" @size="sm">
        Cancel
      </Button>
    </e.Content>
  </Empty>
</template>
