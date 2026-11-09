import { Combobox } from '@ember-joinery/ember'

const frameworks = ['Next.js', 'SvelteKit', 'Nuxt.js', 'Remix', 'Astro'] as const

<template>
  <Combobox @items={{frameworks}} as |c|>
    <c.Input placeholder="Select a framework" />
    <c.Content>
      <c.Empty>No items found.</c.Empty>
      <c.List as |item|>
        <c.Item @value={{item}}>
          {{item}}
        </c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>
