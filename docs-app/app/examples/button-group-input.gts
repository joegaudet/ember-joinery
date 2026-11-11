import { Search } from 'lucide'
import { Button, ButtonGroup, Icon, Input } from '@ember-joinery/ember'

<template>
  <ButtonGroup>
    <Input placeholder="Search..." />
    <Button @variant="outline" aria-label="Search">
      <Icon @icon={{Search}} />
    </Button>
  </ButtonGroup>
</template>
