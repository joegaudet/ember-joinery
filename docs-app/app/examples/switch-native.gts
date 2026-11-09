import { Switch } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example: upstream's switch-demo, line for line, but for its label. Upstream's
    is its Label component, which hasn't landed yet; until it does, this is a native label,
    with the classes upstream's Label has.
  }}
  <div class="flex items-center space-x-2">
    <Switch id="airplane-mode-native" />
    <label for="airplane-mode-native" class="text-sm leading-none font-medium select-none">
      Airplane Mode
    </label>
  </div>
</template>
