import { Search } from 'lucide'
import { Icon, InputGroup } from '@ember-joinery/ember'

<template>
  <InputGroup class="max-w-xs" as |g|>
    <g.Input placeholder="Search..." />
    <g.Addon>
      <Icon @icon={{Search}} />
    </g.Addon>
    <g.Addon @align="inline-end">12 results</g.Addon>
  </InputGroup>
</template>
