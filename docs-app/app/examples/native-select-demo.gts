import { NativeSelect } from '@ember-joinery/ember'

<template>
  {{! Upstream's select has no name; Joinery's gets aria-label, so the audit passes. }}
  <NativeSelect aria-label="Status" as |s|>
    <s.Option @value="">Select status</s.Option>
    <s.Option @value="todo">Todo</s.Option>
    <s.Option @value="in-progress">In Progress</s.Option>
    <s.Option @value="done">Done</s.Option>
    <s.Option @value="cancelled">Cancelled</s.Option>
  </NativeSelect>
</template>
