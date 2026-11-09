import { Avatar, AvatarGroup } from '@ember-joinery/ember'

<template>
  <AvatarGroup class="grayscale">
    <Avatar as |a|>
      <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
      <a.Fallback>CN</a.Fallback>
    </Avatar>
    <Avatar as |a|>
      <a.Image @src="https://github.com/maxleiter.png" alt="@maxleiter" />
      <a.Fallback>LR</a.Fallback>
    </Avatar>
    <Avatar as |a|>
      <a.Image @src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
      <a.Fallback>ER</a.Fallback>
    </Avatar>
  </AvatarGroup>
</template>
