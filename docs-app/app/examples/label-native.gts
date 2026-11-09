import { Label } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example. Upstream's label each label a Checkbox, which comes with the inputs;
    until it lands, this one labels native controls. The second checkbox is disabled and marked
    as the label's peer, so the label dims beside it.
  }}
  <div class="flex flex-col gap-4">
    <div class="flex gap-2">
      <input type="checkbox" id="terms-native" />
      <Label for="terms-native">Accept terms and conditions</Label>
    </div>
    <div class="flex gap-2">
      <input type="checkbox" id="marketing-native" class="peer" disabled />
      <Label for="marketing-native">Send me marketing emails</Label>
    </div>
  </div>
</template>
