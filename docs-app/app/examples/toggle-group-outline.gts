import { ToggleGroup } from '@ember-joinery/ember'

<template>
  <ToggleGroup @variant="outline" @type="single" @defaultValue="all" as |g|>
    <g.Item @value="all" aria-label="Toggle all">
      All
    </g.Item>
    <g.Item @value="missed" aria-label="Toggle missed">
      Missed
    </g.Item>
  </ToggleGroup>
</template>
