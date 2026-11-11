import { ArrowUp } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'

<template>
  <main class="mx-auto max-w-2xl px-4 py-8">
    <h1 class="text-3xl font-bold tracking-tight">Joinery in a Tailwind app</h1>
    <p class="mt-4 text-muted-foreground">
      This app compiles Tailwind CSS v4 with its Vite plugin, next to Joinery's CSS. CI builds it
      and runs its smoke test.
    </p>
    <p class="mt-4 flex gap-2">
      <Button @name="save" @variant="outline">Save</Button>
      <Button @name="up" @size="icon" class="rounded-full" aria-label="Back to top">
        <Icon @icon={{ArrowUp}} />
      </Button>
    </p>
  </main>
</template>
