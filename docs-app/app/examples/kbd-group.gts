import { Kbd, KbdGroup } from '@ember-joinery/ember'

<template>
  <div class="flex flex-col items-center gap-4">
    <p class="text-sm text-muted-foreground">
      Use
      <KbdGroup>
        <Kbd>Ctrl + B</Kbd>
        <Kbd>Ctrl + K</Kbd>
      </KbdGroup>
      to open the command palette
    </p>
  </div>
</template>
