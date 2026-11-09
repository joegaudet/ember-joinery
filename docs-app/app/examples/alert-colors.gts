import { AlertTriangle } from 'lucide'
import { Alert, Icon } from '@ember-joinery/ember'

<template>
  <Alert
    class="max-w-md border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-50"
    as |a|
  >
    <Icon @icon={{AlertTriangle}} />
    <a.Title>Your subscription will expire in 3 days.</a.Title>
    <a.Description>
      Renew now to avoid service interruption or upgrade to a paid plan to continue using the
      service.
    </a.Description>
  </Alert>
</template>
