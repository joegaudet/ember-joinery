import { ChevronsUpDown } from 'lucide'
import { NativeSelect } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example: upstream's NativeSelect is copied into your app, so you change its
    icon by editing it. Joinery's comes from the package, so give it the icon with @icon: any
    lucide icon, imported one at a time.
  }}
  <NativeSelect @icon={{ChevronsUpDown}} aria-label="Sort by" as |s|>
    <s.Option @value="newest">Newest</s.Option>
    <s.Option @value="oldest">Oldest</s.Option>
    <s.Option @value="popular">Most popular</s.Option>
  </NativeSelect>
</template>
