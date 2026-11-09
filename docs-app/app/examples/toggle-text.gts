import { Italic } from 'lucide'
import { Icon, Toggle } from '@ember-joinery/ember'

<template>
  <Toggle aria-label="Toggle italic">
    <Icon @icon={{Italic}} />
    Italic
  </Toggle>
</template>
