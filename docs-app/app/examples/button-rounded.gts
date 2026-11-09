import { ArrowUp } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'

<template>
  <div class="flex flex-col gap-8">
    {{! Upstream's has no label; an icon-only button needs one, so this one is named. }}
    <Button @variant="outline" @size="icon" class="rounded-full" aria-label="Submit">
      <Icon @icon={{ArrowUp}} />
    </Button>
  </div>
</template>
