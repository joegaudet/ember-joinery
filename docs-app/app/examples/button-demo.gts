import { ArrowUp } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'

<template>
  <div class="flex flex-wrap items-center gap-2 md:flex-row">
    <Button @variant="outline">Button</Button>
    <Button @variant="outline" @size="icon" aria-label="Submit">
      <Icon @icon={{ArrowUp}} />
    </Button>
  </div>
</template>
