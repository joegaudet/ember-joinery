import { array } from '@ember/helper'
import { Bold, Italic, Underline } from 'lucide'
import { Icon, ToggleGroup } from '@ember-joinery/ember'

<template>
  <ToggleGroup
    @type="multiple"
    @orientation="vertical"
    @spacing={{1}}
    @defaultValue={{array "bold" "italic"}}
    as |g|
  >
    <g.Item @value="bold" aria-label="Toggle bold">
      <Icon @icon={{Bold}} />
    </g.Item>
    <g.Item @value="italic" aria-label="Toggle italic">
      <Icon @icon={{Italic}} />
    </g.Item>
    <g.Item @value="underline" aria-label="Toggle underline">
      <Icon @icon={{Underline}} />
    </g.Item>
  </ToggleGroup>
</template>
