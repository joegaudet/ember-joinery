import { CircleFadingArrowUp } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's has no label; an icon-only button needs one, so this one is named. }}
  <Button @variant="outline" @size="icon" aria-label="Upgrade">
    <Icon @icon={{CircleFadingArrowUp}} />
  </Button>
</template>
