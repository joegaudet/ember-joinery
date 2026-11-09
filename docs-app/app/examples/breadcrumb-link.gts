import { Breadcrumb } from '@ember-joinery/ember'

<template>
  {{!-- Upstream's <BreadcrumbLink asChild><Link href="/">: the b.link modifier on your own
        link. With the router, it's <LinkTo @route="index" {{b.link}}>. --}}
  <Breadcrumb as |b|>
    <b.List>
      <b.Item>
        <a href="/" {{b.link}}>Home</a>
      </b.Item>
      <b.Separator />
      <b.Item>
        <a href="/components" {{b.link}}>Components</a>
      </b.Item>
      <b.Separator />
      <b.Item>
        <b.Page>Breadcrumb</b.Page>
      </b.Item>
    </b.List>
  </Breadcrumb>
</template>
