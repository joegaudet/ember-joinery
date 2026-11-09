import { Badge, Button, Card } from '@ember-joinery/ember'

<template>
  <Card class="relative mx-auto w-full max-w-sm pt-0" as |c|>
    <div class="absolute inset-0 z-30 aspect-video bg-black/35"></div>
    <img
      src="https://avatar.vercel.sh/shadcn1"
      alt="Event cover"
      class="relative z-20 aspect-video w-full object-cover brightness-60 grayscale dark:brightness-40"
    />
    <c.Header>
      <c.Action>
        <Badge @variant="secondary">Featured</Badge>
      </c.Action>
      <c.Title>Design systems meetup</c.Title>
      <c.Description>
        A practical talk on component APIs, accessibility, and shipping faster.
      </c.Description>
    </c.Header>
    <c.Footer>
      <Button class="w-full">View Event</Button>
    </c.Footer>
  </Card>
</template>
