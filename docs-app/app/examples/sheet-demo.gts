import { Button, Input, Label, Sheet } from '@ember-joinery/ember'

<template>
  <Sheet as |s|>
    <Button @variant="outline" {{s.trigger}}>Open</Button>
    <s.Content>
      <s.Header>
        <s.Title>Edit profile</s.Title>
        <s.Description>
          Make changes to your profile here. Click save when you're done.
        </s.Description>
      </s.Header>
      <div class="grid flex-1 auto-rows-min gap-6 px-4">
        <div class="grid gap-3">
          <Label for="sheet-demo-name">Name</Label>
          <Input id="sheet-demo-name" @defaultValue="Pedro Duarte" />
        </div>
        <div class="grid gap-3">
          <Label for="sheet-demo-username">Username</Label>
          <Input id="sheet-demo-username" @defaultValue="@peduarte" />
        </div>
      </div>
      <s.Footer>
        <Button type="submit">Save changes</Button>
        <Button @variant="outline" {{s.close}}>Close</Button>
      </s.Footer>
    </s.Content>
  </Sheet>
</template>
