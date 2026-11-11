import { Kbd, KbdGroup } from '@ember-joinery/ember'

<template>
  {{! Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor). Upstream's keys are the same in every language. }}
  <div class="flex flex-col items-center gap-4">
    <KbdGroup>
      <Kbd>⌘</Kbd>
      <Kbd>⇧</Kbd>
      <Kbd>⌥</Kbd>
      <Kbd>⌃</Kbd>
    </KbdGroup>
    <KbdGroup>
      <Kbd>Ctrl</Kbd>
      <span>+</span>
      <Kbd>B</Kbd>
    </KbdGroup>
  </div>
</template>
