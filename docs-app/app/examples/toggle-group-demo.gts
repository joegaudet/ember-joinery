import { Bold, Italic, Underline } from 'lucide'
import { Icon, ToggleGroup } from '@ember-joinery/ember'

<template>
  <ToggleGroup @variant="outline" @type="multiple" as |g|>
    <g.Item @value="bold" aria-label="Toggle bold">
      <Icon @icon={{Bold}} />
    </g.Item>
    <g.Item @value="italic" aria-label="Toggle italic">
      <Icon @icon={{Italic}} />
    </g.Item>
    <g.Item @value="strikethrough" aria-label="Toggle strikethrough">
      <Icon @icon={{Underline}} />
    </g.Item>
  </ToggleGroup>
</template>
