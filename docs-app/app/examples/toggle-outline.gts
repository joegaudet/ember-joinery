import { Bold, Italic } from 'lucide'
import { Icon, Toggle } from '@ember-joinery/ember'

<template>
  <div class="flex flex-wrap items-center gap-2">
    <Toggle @variant="outline" aria-label="Toggle italic">
      <Icon @icon={{Italic}} />
      Italic
    </Toggle>
    <Toggle @variant="outline" aria-label="Toggle bold">
      <Icon @icon={{Bold}} />
      Bold
    </Toggle>
  </div>
</template>
