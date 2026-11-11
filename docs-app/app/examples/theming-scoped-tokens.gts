import { Badge, Button, Card } from '@ember-joinery/ember'

/**
 * The tokens are CSS custom properties, so they cascade: set some on an element, and every
 * component inside it takes them, here a blue primary and a larger radius on one card.
 */
<template>
  <div class="flex flex-wrap items-start gap-4">
    <Card class="w-56" as |c|>
      <c.Header>
        <c.Title>Default</c.Title>
        <c.Description>The theme's tokens.</c.Description>
      </c.Header>
      <c.Footer class="gap-2">
        <Button>Save</Button>
        <Badge>New</Badge>
      </c.Footer>
    </Card>
    <Card
      class="w-56"
      style="--primary: oklch(0.488 0.243 264.376); --primary-foreground: oklch(0.97 0.014 254.604); --radius: 1rem"
      as |c|
    >
      <c.Header>
        <c.Title>Blue</c.Title>
        <c.Description>Its own primary and radius.</c.Description>
      </c.Header>
      <c.Footer class="gap-2">
        <Button>Save</Button>
        <Badge>New</Badge>
      </c.Footer>
    </Card>
  </div>
</template>
