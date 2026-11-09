import { service } from '@ember-joinery/primitives/service'

/** A registered service, read in a template with no backing class: the router. */
<template>
  {{#let (service "router") as |router|}}
    <p data-test-jn="current-page">
      You are on
      <code data-test-jn-part="url">{{router.currentURL}}</code>
    </p>
  {{/let}}
</template>
