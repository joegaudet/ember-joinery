import { Plus } from 'lucide'
import { Avatar, Icon } from '@ember-joinery/ember'

<template>
  <Avatar class="grayscale" as |a|>
    <a.Image @src="https://github.com/pranathip.png" alt="@pranathip" />
    <a.Fallback>PP</a.Fallback>
    <a.Badge>
      <Icon @icon={{Plus}} />
    </a.Badge>
  </Avatar>
</template>
