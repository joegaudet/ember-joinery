import { Check, CreditCard, Info, Mail, Search, Star } from 'lucide'
import { Icon, InputGroup } from '@ember-joinery/ember'

<template>
  <div class="grid w-full max-w-sm gap-6">
    <InputGroup as |g|>
      <g.Input placeholder="Search..." />
      <g.Addon>
        <Icon @icon={{Search}} />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input type="email" placeholder="Enter your email" />
      <g.Addon>
        <Icon @icon={{Mail}} />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="Card number" />
      <g.Addon>
        <Icon @icon={{CreditCard}} />
      </g.Addon>
      <g.Addon @align="inline-end">
        <Icon @icon={{Check}} />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="Card number" />
      <g.Addon @align="inline-end">
        <Icon @icon={{Star}} />
        <Icon @icon={{Info}} />
      </g.Addon>
    </InputGroup>
  </div>
</template>
