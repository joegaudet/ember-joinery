import { ToggleGroup } from '@ember-joinery/ember'

<template>
  <ToggleGroup
    @type="single"
    @size="sm"
    @defaultValue="top"
    @variant="outline"
    @spacing={{2}}
    as |g|
  >
    <g.Item @value="top" aria-label="Toggle top">
      Top
    </g.Item>
    <g.Item @value="bottom" aria-label="Toggle bottom">
      Bottom
    </g.Item>
    <g.Item @value="left" aria-label="Toggle left">
      Left
    </g.Item>
    <g.Item @value="right" aria-label="Toggle right">
      Right
    </g.Item>
  </ToggleGroup>
</template>
