import { ChevronDown, Dot } from 'lucide'
import { Breadcrumb, DropdownMenu, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's links are Next's <Link> (asChild); b.Link renders the same <a>. }}
  <Breadcrumb as |b|>
    <b.List>
      <b.Item>
        <b.Link href="/">Home</b.Link>
      </b.Item>
      <b.Separator>
        <Icon @icon={{Dot}} />
      </b.Separator>
      <b.Item>
        <DropdownMenu as |m|>
          <button type="button" class="flex items-center gap-1" {{m.trigger}}>
            Components
            <Icon @icon={{ChevronDown}} class="size-3.5" />
          </button>
          <m.Content @align="start">
            <m.Group>
              <m.Item>Documentation</m.Item>
              <m.Item>Themes</m.Item>
              <m.Item>GitHub</m.Item>
            </m.Group>
          </m.Content>
        </DropdownMenu>
      </b.Item>
      <b.Separator>
        <Icon @icon={{Dot}} />
      </b.Separator>
      <b.Item>
        <b.Page>Breadcrumb</b.Page>
      </b.Item>
    </b.List>
  </Breadcrumb>
</template>
