import { array, get } from '@ember/helper'
import { Combobox } from '@ember-joinery/ember'

const frameworks = ['Next.js', 'SvelteKit', 'Nuxt.js', 'Remix', 'Astro'] as const

<template>
  {{!
    Upstream's useComboboxAnchor is the yielded chipsElement. Its chips input has no label;
    this one is named with aria-label, as an input must be.
  }}
  <Combobox
    @multiple={{true}}
    @autoHighlight={{true}}
    @items={{frameworks}}
    @defaultValue={{array (get frameworks 0)}}
    as |c|
  >
    <c.Chips class="w-full max-w-xs">
      <c.Value as |values|>
        {{#each values as |value|}}
          <c.Chip @value={{value}}>{{value}}</c.Chip>
        {{/each}}
        <c.ChipsInput aria-label="Frameworks" />
      </c.Value>
    </c.Chips>
    <c.Content @anchor={{c.chipsElement}}>
      <c.Empty>No items found.</c.Empty>
      <c.List as |item|>
        <c.Item @value={{item}}>
          {{item}}
        </c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>
