import { Card, Skeleton } from '@ember-joinery/ember'

<template>
  <Card class="w-full max-w-xs" as |c|>
    <c.Header>
      <Skeleton class="h-4 w-2/3" />
      <Skeleton class="h-4 w-1/2" />
    </c.Header>
    <c.Content>
      <Skeleton class="aspect-video w-full" />
    </c.Content>
  </Card>
</template>
