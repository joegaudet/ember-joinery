import { Button, Sheet } from '@ember-joinery/ember'

<template>
  <Sheet as |s|>
    <Button @variant="outline" {{s.trigger}}>Open Sheet</Button>
    <s.Content @showCloseButton={{false}}>
      <s.Header>
        <s.Title>No Close Button</s.Title>
        <s.Description>
          This sheet doesn't have a close button in the top-right corner. Click outside to close.
        </s.Description>
      </s.Header>
    </s.Content>
  </Sheet>
</template>
