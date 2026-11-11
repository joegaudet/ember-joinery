import { Item, ItemGroup } from '@ember-joinery/ember'

const music = [
  {
    title: 'Midnight City Lights',
    artist: 'Neon Dreams',
    album: 'Electric Nights',
    duration: '3:45',
  },
  {
    title: 'Coffee Shop Conversations',
    artist: 'The Morning Brew',
    album: 'Urban Stories',
    duration: '4:05',
  },
  {
    title: 'Digital Rain',
    artist: 'Cyber Symphony',
    album: 'Binary Beats',
    duration: '3:30',
  },
]

<template>
  {{!
    Upstream's next/image is a plain <img>, at the size it asks for. Upstream puts
    role="listitem" on each link, which takes the link's own role away; here a <div> around
    each link is the list item, so the links stay links and the audit passes. It draws nothing.
  }}
  <div class="flex w-full max-w-md flex-col gap-6">
    <ItemGroup class="gap-4">
      {{#each music as |song|}}
        <div role="listitem">
          <Item @variant="outline" @as="a" href="#" as |i|>
            <i.Media @variant="image">
              <img
                src="https://avatar.vercel.sh/{{song.title}}"
                alt={{song.title}}
                width="32"
                height="32"
                class="object-cover grayscale"
              />
            </i.Media>
            <i.Content>
              <i.Title class="line-clamp-1">
                {{song.title}}
                -
                <span class="text-muted-foreground">{{song.album}}</span>
              </i.Title>
              <i.Description>{{song.artist}}</i.Description>
            </i.Content>
            <i.Content class="flex-none text-center">
              <i.Description>{{song.duration}}</i.Description>
            </i.Content>
          </Item>
        </div>
      {{/each}}
    </ItemGroup>
  </div>
</template>
