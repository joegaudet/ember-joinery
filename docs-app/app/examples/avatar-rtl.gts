import { Avatar, AvatarGroup } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: the count is "+٣". The badge moves to the bottom left corner, and the group
    overlaps from the other side.
  }}
  <div class="flex flex-row flex-wrap items-center gap-6 md:gap-12">
    <Avatar as |a|>
      <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" class="grayscale" />
      <a.Fallback>CN</a.Fallback>
    </Avatar>
    <Avatar as |a|>
      <a.Image @src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
      <a.Fallback>ER</a.Fallback>
      <a.Badge class="bg-green-600 dark:bg-green-800" />
    </Avatar>
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
      <g.Count>+٣</g.Count>
    </AvatarGroup>
  </div>
</template>
