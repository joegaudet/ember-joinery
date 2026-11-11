import { Button, Popover } from '@ember-joinery/ember'

<template>
  <Popover as |p|>
    <Button @variant="outline" {{p.trigger}}>Open Popover</Button>
    <p.Content @align="start">
      <p.Header>
        <p.Title>Dimensions</p.Title>
        <p.Description>
          Set the dimensions for the layer.
        </p.Description>
      </p.Header>
    </p.Content>
  </Popover>
</template>
