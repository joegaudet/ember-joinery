import { Checkbox } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example. Upstream's label each checkbox with Field and Label, which haven't
    landed yet; until they do, these use native labels, with the classes upstream's Label has.
    The disabled checkbox is the label's peer, so the label dims beside it.
  }}
  <div class="flex max-w-sm flex-col gap-6">
    <div class="flex items-center gap-3">
      <Checkbox id="terms-checkbox-native" />
      <label for="terms-checkbox-native" class="text-sm leading-none font-medium select-none">
        Accept terms and conditions
      </label>
    </div>
    <div class="flex items-start gap-3">
      <Checkbox id="terms-checkbox-native-2" @defaultChecked={{true}} />
      <div class="grid gap-2">
        <label
          for="terms-checkbox-native-2"
          class="text-sm leading-none font-medium select-none"
        >Accept terms and conditions</label>
        <p class="text-sm text-muted-foreground">
          By clicking this checkbox, you agree to the terms.
        </p>
      </div>
    </div>
    <div class="flex items-center gap-3">
      <Checkbox id="toggle-checkbox-native" @disabled={{true}} />
      <label
        for="toggle-checkbox-native"
        class="text-sm leading-none font-medium select-none peer-disabled:cursor-not-allowed peer-disabled:opacity-50"
      >Enable notifications</label>
    </div>
  </div>
</template>
