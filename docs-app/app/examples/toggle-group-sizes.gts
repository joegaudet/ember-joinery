import { ToggleGroup } from '@ember-joinery/ember'

<template>
  <div class="flex flex-col gap-4">
    <ToggleGroup @type="single" @size="sm" @defaultValue="top" @variant="outline" as |g|>
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
    <ToggleGroup @type="single" @defaultValue="top" @variant="outline" as |g|>
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
  </div>
</template>
