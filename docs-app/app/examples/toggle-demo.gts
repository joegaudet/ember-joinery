import { Bookmark } from 'lucide'
import { Icon, Toggle } from '@ember-joinery/ember'

<template>
  <Toggle aria-label="Toggle bookmark" @size="sm" @variant="outline">
    <Icon @icon={{Bookmark}} class="group-data-[state=on]/toggle:fill-foreground" />
    Bookmark
  </Toggle>
</template>
