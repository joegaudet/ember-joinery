import { Globe } from 'lucide'
import { Combobox, Icon } from '@ember-joinery/ember'

const timezones = [
  {
    value: 'Americas',
    items: [
      '(GMT-5) New York',
      '(GMT-8) Los Angeles',
      '(GMT-6) Chicago',
      '(GMT-5) Toronto',
      '(GMT-8) Vancouver',
      '(GMT-3) São Paulo',
    ],
  },
  {
    value: 'Europe',
    items: [
      '(GMT+0) London',
      '(GMT+1) Paris',
      '(GMT+1) Berlin',
      '(GMT+1) Rome',
      '(GMT+1) Madrid',
      '(GMT+1) Amsterdam',
    ],
  },
  {
    value: 'Asia/Pacific',
    items: [
      '(GMT+9) Tokyo',
      '(GMT+8) Shanghai',
      '(GMT+8) Singapore',
      '(GMT+4) Dubai',
      '(GMT+11) Sydney',
      '(GMT+9) Seoul',
    ],
  },
] as const

<template>
  {{! Upstream's InputGroupAddon inside ComboboxInput is the addon c.Input yields. }}
  <Combobox @items={{timezones}} as |c|>
    <c.Input placeholder="Select a timezone" as |g|>
      <g.Addon>
        <Icon @icon={{Globe}} />
      </g.Addon>
    </c.Input>
    <c.Content @alignOffset={{-28}} class="w-60">
      <c.Empty>No timezones found.</c.Empty>
      <c.List as |group|>
        <c.Group @items={{group.items}} as |g|>
          <c.Label>{{group.value}}</c.Label>
          <g.Collection as |item|>
            <c.Item @value={{item}}>
              {{item}}
            </c.Item>
          </g.Collection>
        </c.Group>
      </c.List>
    </c.Content>
  </Combobox>
</template>
