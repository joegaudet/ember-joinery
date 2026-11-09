import { NativeSelect } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example: upstream's NativeSelect takes size="sm", but no example on its page
    shows it. Each select keeps its own value, starting from @defaultValue.
  }}
  <div class="flex items-center gap-2">
    <NativeSelect @name="sm" @size="sm" @defaultValue="week" aria-label="Small" as |s|>
      <s.Option @value="day">Today</s.Option>
      <s.Option @value="week">This week</s.Option>
      <s.Option @value="month">This month</s.Option>
    </NativeSelect>
    <NativeSelect @name="default" @defaultValue="week" aria-label="Default" as |s|>
      <s.Option @value="day">Today</s.Option>
      <s.Option @value="week">This week</s.Option>
      <s.Option @value="month">This month</s.Option>
    </NativeSelect>
  </div>
</template>
