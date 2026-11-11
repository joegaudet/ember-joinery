import { AppWindow, Code } from 'lucide'
import { Icon, Tabs } from '@ember-joinery/ember'

<template>
  <Tabs @defaultValue="preview" as |t|>
    <t.List>
      <t.Trigger @value="preview">
        <Icon @icon={{AppWindow}} />
        Preview
      </t.Trigger>
      <t.Trigger @value="code">
        <Icon @icon={{Code}} />
        Code
      </t.Trigger>
    </t.List>
  </Tabs>
</template>
