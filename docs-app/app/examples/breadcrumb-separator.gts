import { Dot } from 'lucide'
import { Breadcrumb, Icon } from '@ember-joinery/ember'

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
        <b.Link href="/components">Components</b.Link>
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
