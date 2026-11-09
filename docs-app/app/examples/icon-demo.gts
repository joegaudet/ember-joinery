import { Bell, Heart, Search, Trash2 } from 'lucide'
import { Icon } from '@ember-joinery/ember'

<template>
  <div class="flex items-center gap-4">
    <Icon @icon={{Search}} />
    <Icon @icon={{Bell}} @size={{32}} />
    <Icon @icon={{Heart}} @color="var(--destructive)" @strokeWidth={{1.5}} />
    <Icon @icon={{Trash2}} @label="Trash" class="text-muted-foreground" />
  </div>
</template>
