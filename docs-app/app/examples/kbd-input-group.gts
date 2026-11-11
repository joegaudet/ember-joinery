import { Search } from 'lucide'
import { Icon, InputGroup, Kbd } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-xs flex-col gap-6">
    <InputGroup as |g|>
      <g.Input placeholder="Search..." />
      <g.Addon>
        <Icon @icon={{Search}} />
      </g.Addon>
      <g.Addon @align="inline-end">
        <Kbd>⌘</Kbd>
        <Kbd>K</Kbd>
      </g.Addon>
    </InputGroup>
  </div>
</template>
