import { AlertCircle } from 'lucide'
import { Alert, Icon } from '@ember-joinery/ember'

<template>
  <Alert @variant="destructive" class="max-w-md" as |a|>
    <Icon @icon={{AlertCircle}} />
    <a.Title>Payment failed</a.Title>
    <a.Description>
      Your payment could not be processed. Please check your payment method and try again.
    </a.Description>
  </Alert>
</template>
