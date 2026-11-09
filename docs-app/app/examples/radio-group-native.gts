import { RadioGroup } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example: upstream's radio-group-demo, line for line, but for its labels.
    Upstream's are its Label component, which hasn't landed yet; until it does, these are
    native labels, with the classes upstream's Label has.
  }}
  <RadioGroup @defaultValue="comfortable" class="w-fit" as |group|>
    <div class="flex items-center gap-3">
      <group.Item @value="default" id="r1-native" />
      <label for="r1-native" class="text-sm leading-none font-medium select-none">Default</label>
    </div>
    <div class="flex items-center gap-3">
      <group.Item @value="comfortable" id="r2-native" />
      <label for="r2-native" class="text-sm leading-none font-medium select-none">
        Comfortable
      </label>
    </div>
    <div class="flex items-center gap-3">
      <group.Item @value="compact" id="r3-native" />
      <label for="r3-native" class="text-sm leading-none font-medium select-none">Compact</label>
    </div>
  </RadioGroup>
</template>
