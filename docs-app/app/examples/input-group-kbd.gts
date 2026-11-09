import { Search } from 'lucide'
import { Icon, InputGroup, Kbd } from '@ember-joinery/ember'

<template>
  <InputGroup class="max-w-sm" as |g|>
    <g.Input placeholder="Search..." />
    <g.Addon>
      <Icon @icon={{Search}} class="text-muted-foreground" />
    </g.Addon>
    <g.Addon @align="inline-end">
      <Kbd>⌘K</Kbd>
    </g.Addon>
  </InputGroup>
</template>
