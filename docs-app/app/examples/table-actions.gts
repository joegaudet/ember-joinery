import { MoreHorizontal } from 'lucide'
import { Button, DropdownMenu, Icon, Table } from '@ember-joinery/ember'

const products = [
  { name: 'Wireless Mouse', price: '$29.99' },
  { name: 'Mechanical Keyboard', price: '$129.99' },
  { name: 'USB-C Hub', price: '$49.99' },
]

<template>
  {{! Upstream writes the three rows out; they are the same but for the product. }}
  <Table as |t|>
    <t.Header>
      <t.Row>
        <t.Head>Product</t.Head>
        <t.Head>Price</t.Head>
        <t.Head class="text-right">Actions</t.Head>
      </t.Row>
    </t.Header>
    <t.Body>
      {{#each products as |product|}}
        <t.Row>
          <t.Cell class="font-medium">{{product.name}}</t.Cell>
          <t.Cell>{{product.price}}</t.Cell>
          <t.Cell class="text-right">
            <DropdownMenu as |m|>
              <Button @variant="ghost" @size="icon" class="size-8" {{m.trigger}}>
                <Icon @icon={{MoreHorizontal}} />
                <span class="sr-only">Open menu</span>
              </Button>
              <m.Content @align="end">
                <m.Item>Edit</m.Item>
                <m.Item>Duplicate</m.Item>
                <m.Separator />
                <m.Item @variant="destructive">
                  Delete
                </m.Item>
              </m.Content>
            </DropdownMenu>
          </t.Cell>
        </t.Row>
      {{/each}}
    </t.Body>
  </Table>
</template>
