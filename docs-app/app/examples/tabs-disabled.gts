import { Tabs } from '@ember-joinery/ember'

<template>
  <Tabs @defaultValue="home" as |t|>
    <t.List>
      <t.Trigger @value="home">Home</t.Trigger>
      <t.Trigger @value="settings" @disabled={{true}}>
        Disabled
      </t.Trigger>
    </t.List>
  </Tabs>
</template>
