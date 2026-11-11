import { Moon, Sun } from 'lucide'
import { Icon, Switch } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example: the Switch's block renders inside its thumb, with the switch's
    state, so the thumb can show an icon. Upstream's thumb is empty.
  }}
  <div class="flex items-center gap-2">
    <Switch id="dark-mode-thumb" as |thumb|>
      <Icon @icon={{if thumb.isChecked Moon Sun}} class="m-0.5 size-3 text-muted-foreground" />
    </Switch>
    <label for="dark-mode-thumb" class="text-sm leading-none font-medium select-none">
      Dark mode
    </label>
  </div>
</template>
