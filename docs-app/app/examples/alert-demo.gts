import { CheckCircle2, Info } from 'lucide'
import { Alert, Icon } from '@ember-joinery/ember'

<template>
  <div class="grid w-full max-w-md items-start gap-4">
    <Alert as |a|>
      <Icon @icon={{CheckCircle2}} />
      <a.Title>Payment successful</a.Title>
      <a.Description>
        Your payment of $29.99 has been processed. A receipt has been sent to your email address.
      </a.Description>
    </Alert>
    <Alert as |a|>
      <Icon @icon={{Info}} />
      <a.Title>New feature available</a.Title>
      <a.Description>
        We've added dark mode support. You can enable it in your account settings.
      </a.Description>
    </Alert>
  </div>
</template>
