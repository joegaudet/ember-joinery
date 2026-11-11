import { Separator } from '@ember-joinery/ember'

<template>
  <div class="flex h-5 items-center gap-4 text-sm">
    <div>Blog</div>
    <Separator @orientation="vertical" />
    <div>Docs</div>
    <Separator @orientation="vertical" />
    <div>Source</div>
  </div>
</template>
