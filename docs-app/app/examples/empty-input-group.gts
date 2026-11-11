import { Search } from 'lucide'
import { Empty, Icon, InputGroup, Kbd } from '@ember-joinery/ember'

<template>
  <Empty as |e|>
    <e.Header>
      <e.Title>404 - Not Found</e.Title>
      <e.Description>
        The page you're looking for doesn't exist. Try searching for what you need below.
      </e.Description>
    </e.Header>
    <e.Content>
      <InputGroup class="sm:w-3/4" as |g|>
        <g.Input placeholder="Try searching for pages..." />
        <g.Addon>
          <Icon @icon={{Search}} />
        </g.Addon>
        <g.Addon @align="inline-end">
          <Kbd>/</Kbd>
        </g.Addon>
      </InputGroup>
      <e.Description>
        Need help?
        <a href="#">Contact support</a>
      </e.Description>
    </e.Content>
  </Empty>
</template>
