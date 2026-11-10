import { ChevronDown, MoreHorizontal } from 'lucide'
import { DropdownMenu, Icon, InputGroup } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's DropdownMenuTrigger asChild makes each InputGroupButton the trigger, as
    m.trigger does. Upstream's DropdownMenu sits inside the addon and renders no element;
    Joinery's root is an element with display: contents, which inside the addon would come
    between it and its button and lose the addon's has-[>button] pull into its padding. So
    each menu here goes around the addon instead. There the one group rule it hides the addon
    from is the input's smaller end padding beside an inline-end addon, which only moves where
    a long value is clipped.
  }}
  <div class="grid w-full max-w-sm gap-4">
    <InputGroup as |g|>
      <g.Input placeholder="Enter file name" />
      <DropdownMenu as |m|>
        <g.Addon @align="inline-end">
          <g.Button @variant="ghost" aria-label="More" @size="icon-xs" {{m.trigger}}>
            <Icon @icon={{MoreHorizontal}} />
          </g.Button>
        </g.Addon>
        <m.Content @align="end">
          <m.Group>
            <m.Item>Settings</m.Item>
            <m.Item>Copy path</m.Item>
            <m.Item>Open location</m.Item>
          </m.Group>
        </m.Content>
      </DropdownMenu>
    </InputGroup>
    <InputGroup class="[--radius:1rem]" as |g|>
      <g.Input placeholder="Enter search query" />
      <DropdownMenu as |m|>
        <g.Addon @align="inline-end">
          <g.Button @variant="ghost" class="pr-1.5! text-xs" {{m.trigger}}>
            Search In...
            <Icon @icon={{ChevronDown}} class="size-3" />
          </g.Button>
        </g.Addon>
        <m.Content @align="end" class="[--radius:0.95rem]">
          <m.Group>
            <m.Item>Documentation</m.Item>
            <m.Item>Blog Posts</m.Item>
            <m.Item>Changelog</m.Item>
          </m.Group>
        </m.Content>
      </DropdownMenu>
    </InputGroup>
  </div>
</template>
