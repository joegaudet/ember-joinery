import { BadgeCheck, Bookmark } from 'lucide'
import { Badge, Icon } from '@ember-joinery/ember'

<template>
  <div class="flex flex-wrap gap-2">
    <Badge @variant="secondary">
      <Icon @icon={{BadgeCheck}} data-icon="inline-start" />
      Verified
    </Badge>
    <Badge @variant="outline">
      Bookmark
      <Icon @icon={{Bookmark}} data-icon="inline-end" />
    </Badge>
  </div>
</template>
