import { NativeSelect } from '@ember-joinery/ember'

<template>
  {{! Upstream's select has no name; Joinery's gets aria-label, so the audit passes. }}
  <NativeSelect disabled aria-label="Fruit" as |s|>
    <s.Option @value="">Disabled</s.Option>
    <s.Option @value="apple">Apple</s.Option>
    <s.Option @value="banana">Banana</s.Option>
    <s.Option @value="blueberry">Blueberry</s.Option>
  </NativeSelect>
</template>
