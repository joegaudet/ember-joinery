import { Label } from '@ember-joinery/primitives/label'

<template>
  <div class="flex flex-col gap-2 text-sm">
    <Label for="email-headless">Your email address</Label>
    <input id="email-headless" type="email" placeholder="you@example.com" />
  </div>
</template>
