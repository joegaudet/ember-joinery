import { Breadcrumb, Button, DropdownMenu } from '@ember-joinery/ember'

<template>
  {{! Upstream's links are Next's <Link> (asChild); b.Link renders the same <a>. }}
  <Breadcrumb as |b|>
    <b.List>
      <b.Item>
        <b.Link href="#">Home</b.Link>
      </b.Item>
      <b.Separator />
      <b.Item>
        <DropdownMenu as |m|>
          <Button @size="icon-sm" @variant="ghost" {{m.trigger}}>
            <b.Ellipsis />
            <span class="sr-only">Toggle menu</span>
          </Button>
          <m.Content @align="start">
            <m.Group>
              <m.Item>Documentation</m.Item>
              <m.Item>Themes</m.Item>
              <m.Item>GitHub</m.Item>
            </m.Group>
          </m.Content>
        </DropdownMenu>
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
