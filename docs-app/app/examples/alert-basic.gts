import { CheckCircle2 } from 'lucide'
import { Alert, Icon } from '@ember-joinery/ember'

<template>
  <Alert class="max-w-md" as |a|>
    <Icon @icon={{CheckCircle2}} />
    <a.Title>Account updated successfully</a.Title>
    <a.Description>
      Your profile information has been saved. Changes will be reflected immediately.
    </a.Description>
  </Alert>
</template>
