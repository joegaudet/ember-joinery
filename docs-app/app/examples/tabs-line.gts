import { Tabs } from '@ember-joinery/ember'

<template>
  <Tabs @defaultValue="overview" as |t|>
    <t.List @variant="line">
      <t.Trigger @value="overview">Overview</t.Trigger>
      <t.Trigger @value="analytics">Analytics</t.Trigger>
      <t.Trigger @value="reports">Reports</t.Trigger>
    </t.List>
  </Tabs>
</template>
