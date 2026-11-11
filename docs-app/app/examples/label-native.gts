import { Label } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example, for the Label page's Disabled section: it labels native checkboxes.
    The second is disabled and marked as the label's peer, so the label dims beside it.
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
