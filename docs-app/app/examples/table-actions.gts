import { MoreHorizontal } from 'lucide'
import { Button, DropdownMenu, Icon, Table } from '@ember-joinery/ember'

<template>
  <Table as |t|>
    <t.Header>
      <t.Row>
        <t.Head>Product</t.Head>
        <t.Head>Price</t.Head>
        <t.Head class="text-right">Actions</t.Head>
      </t.Row>
    </t.Header>
    <t.Body>
      <t.Row>
        <t.Cell class="font-medium">Wireless Mouse</t.Cell>
        <t.Cell>$29.99</t.Cell>
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
      <t.Row>
        <t.Cell class="font-medium">Mechanical Keyboard</t.Cell>
        <t.Cell>$129.99</t.Cell>
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
      <t.Row>
        <t.Cell class="font-medium">USB-C Hub</t.Cell>
        <t.Cell>$49.99</t.Cell>
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
    </t.Body>
  </Table>
</template>
