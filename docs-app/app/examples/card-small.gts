import { Button, Card } from '@ember-joinery/ember'

<template>
  <Card @size="sm" class="mx-auto w-full max-w-sm" as |c|>
    <c.Header>
      <c.Title>Small Card</c.Title>
      <c.Description>
        This card uses the small size variant.
      </c.Description>
    </c.Header>
    <c.Content>
      <p>
        The card component supports a size prop that can be set to "sm" for a more compact
        appearance.
      </p>
    </c.Content>
    <c.Footer>
      <Button @variant="outline" @size="sm" class="w-full">
        Action
      </Button>
    </c.Footer>
  </Card>
</template>
