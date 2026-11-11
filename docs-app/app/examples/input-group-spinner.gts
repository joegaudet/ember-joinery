import { Loader } from 'lucide'
import { Icon, InputGroup, Spinner } from '@ember-joinery/ember'

<template>
  <div class="grid w-full max-w-sm gap-4">
    <InputGroup as |g|>
      <g.Input placeholder="Searching..." />
      <g.Addon @align="inline-end">
        <Spinner />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="Processing..." />
      <g.Addon>
        <Spinner />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="Saving changes..." />
      <g.Addon @align="inline-end">
        <g.Text>Saving...</g.Text>
        <Spinner />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="Refreshing data..." />
      <g.Addon>
        <Icon @icon={{Loader}} class="animate-spin" />
      </g.Addon>
      <g.Addon @align="inline-end">
        <g.Text class="text-muted-foreground">
          Please wait...
        </g.Text>
      </g.Addon>
    </InputGroup>
  </div>
</template>
