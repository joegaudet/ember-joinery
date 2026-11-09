import { ArrowUp } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'

<template>
  <main>
    <h1>Joinery in a Vite app</h1>
    <p>
      This app imports Joinery's packages and CSS the way a Vite (Embroider) app does. CI builds it
      and runs its smoke test.
    </p>
    <p>
      <Button @name="save" @variant="outline">Save</Button>
      <Button @name="up" @size="icon" aria-label="Back to top"><Icon @icon={{ArrowUp}} /></Button>
    </p>
  </main>
</template>
