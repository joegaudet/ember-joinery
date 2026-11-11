import { Avatar } from '@ember-joinery/ember'

<template>
  <Avatar as |a|>
    <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
    <a.Fallback>CN</a.Fallback>
    <a.Badge class="bg-green-600 dark:bg-green-800" />
  </Avatar>
</template>
