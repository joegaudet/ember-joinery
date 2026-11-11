import { Button, HoverCard } from '@ember-joinery/ember'

<template>
  <HoverCard @openDelay={{10}} @closeDelay={{100}} as |h|>
    <Button @variant="link" {{h.trigger}}>Hover Here</Button>
    <h.Content class="flex w-64 flex-col gap-0.5">
      <div class="font-semibold">@nextjs</div>
      <div>The React Framework – created and maintained by @vercel.</div>
      <div class="mt-1 text-xs text-muted-foreground">
        Joined December 2021
      </div>
    </h.Content>
  </HoverCard>
</template>
