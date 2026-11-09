import { Label, RadioGroup } from '@ember-joinery/ember'

<template>
  <RadioGroup @defaultValue="comfortable" class="w-fit" as |group|>
    <div class="flex items-center gap-3">
      <group.Item @value="default" id="r1" />
      <Label for="r1">Default</Label>
    </div>
    <div class="flex items-center gap-3">
      <group.Item @value="comfortable" id="r2" />
      <Label for="r2">Comfortable</Label>
    </div>
    <div class="flex items-center gap-3">
      <group.Item @value="compact" id="r3" />
      <Label for="r3">Compact</Label>
    </div>
  </RadioGroup>
</template>
