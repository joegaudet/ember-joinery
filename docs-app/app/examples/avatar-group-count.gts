import { Avatar, AvatarGroup } from '@ember-joinery/ember'

<template>
  <AvatarGroup class="grayscale" as |g|>
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
    <g.Count>+3</g.Count>
  </AvatarGroup>
</template>
