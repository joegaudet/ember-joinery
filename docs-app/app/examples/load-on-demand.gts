import { load } from '@ember-joinery/primitives/load'

/** Loads the summary's code when it first renders: it is its own chunk of the bundle. */
const Summary = load<{ Args: { year: number } }>(() => import('./lazy/revenue-summary.gts'))

<template>
  <Summary>
    <:loading>
      <p role="status">Loading the summary…</p>
    </:loading>
    <:error as |error|>
      <p role="alert">The summary didn't load: {{error.reason}}</p>
    </:error>
    <:success as |RevenueSummary|>
      <RevenueSummary @year={{2026}} />
    </:success>
  </Summary>
</template>
