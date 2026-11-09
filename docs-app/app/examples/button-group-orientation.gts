import { Minus, Plus } from 'lucide'
import { Button, ButtonGroup, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's icon buttons have no labels; an icon-only button needs one, so these are named. }}
  <ButtonGroup @orientation="vertical" aria-label="Media controls" class="h-fit">
    <Button @variant="outline" @size="icon" aria-label="Increase">
      <Icon @icon={{Plus}} />
    </Button>
    <Button @variant="outline" @size="icon" aria-label="Decrease">
      <Icon @icon={{Minus}} />
    </Button>
  </ButtonGroup>
</template>
