import { Tabs } from '@ember-joinery/primitives/tabs'

<template>
  {{!
    The primitive, unstyled but for the classes here, as ember-primitives' own demo: tabs that
    select on Enter, Space or a click (manual activation), not as focus moves.
  }}
  <Tabs @defaultValue="npm" @activationMode="manual" class="w-80" as |t|>
    <t.List aria-label="Install with your package manager" class="flex gap-1 border-b">
      <t.Trigger
        @value="npm"
        class="-mb-px border-0 border-b-2 border-transparent bg-transparent px-3 py-1.5 text-sm text-muted-foreground data-[state=active]:border-foreground data-[state=active]:text-foreground"
      >npm</t.Trigger>
      <t.Trigger
        @value="pnpm"
        class="-mb-px border-0 border-b-2 border-transparent bg-transparent px-3 py-1.5 text-sm text-muted-foreground data-[state=active]:border-foreground data-[state=active]:text-foreground"
      >pnpm</t.Trigger>
      <t.Trigger
        @value="yarn"
        class="-mb-px border-0 border-b-2 border-transparent bg-transparent px-3 py-1.5 text-sm text-muted-foreground data-[state=active]:border-foreground data-[state=active]:text-foreground"
      >yarn</t.Trigger>
    </t.List>
    <t.Content @value="npm" class="p-3 font-mono text-sm">npm add @ember-joinery/primitives</t.Content>
    <t.Content @value="pnpm" class="p-3 font-mono text-sm">pnpm add @ember-joinery/primitives</t.Content>
    <t.Content @value="yarn" class="p-3 font-mono text-sm">yarn add @ember-joinery/primitives</t.Content>
  </Tabs>
</template>
