import { Button, Field, Input } from '@ember-joinery/ember'

<template>
  {{! The search input gets an aria-label, which upstream's leaves off, so the audit passes. }}
  <Field @orientation="horizontal">
    <Input type="search" placeholder="Search..." aria-label="Search" />
    <Button>Search</Button>
  </Field>
</template>
