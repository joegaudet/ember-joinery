import { Avatar } from '@ember-joinery/ember'

<template>
  <div class="flex flex-wrap items-center gap-2 grayscale">
    <Avatar @size="sm" as |a|>
      <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
      <a.Fallback>CN</a.Fallback>
    </Avatar>
    <Avatar as |a|>
      <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
      <a.Fallback>CN</a.Fallback>
    </Avatar>
    <Avatar @size="lg" as |a|>
      <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
      <a.Fallback>CN</a.Fallback>
    </Avatar>
  </div>
</template>
