import { Breadcrumb } from '@ember-joinery/ember'

<template>
  <Breadcrumb as |b|>
    <b.List>
      <b.Item>
        <b.Link href="#">Home</b.Link>
      </b.Item>
      <b.Separator />
      <b.Item>
        <b.Link href="#">Components</b.Link>
      </b.Item>
      <b.Separator />
      <b.Item>
        <b.Page>Breadcrumb</b.Page>
      </b.Item>
    </b.List>
  </Breadcrumb>
</template>
