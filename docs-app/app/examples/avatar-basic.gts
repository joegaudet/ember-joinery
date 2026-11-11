import { Avatar } from '@ember-joinery/ember'

<template>
  <Avatar as |a|>
    <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" class="grayscale" />
    <a.Fallback>CN</a.Fallback>
  </Avatar>
</template>
