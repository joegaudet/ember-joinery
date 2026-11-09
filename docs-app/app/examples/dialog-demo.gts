import { Button, Dialog, Field, FieldGroup, Input, Label } from '@ember-joinery/ember'

<template>
  <Dialog as |d|>
    <form>
      <Button @variant="outline" {{d.trigger}}>Open Dialog</Button>
      <d.Content class="sm:max-w-sm">
        <d.Header>
          <d.Title>Edit profile</d.Title>
          <d.Description>
            Make changes to your profile here. Click save when you're done.
          </d.Description>
        </d.Header>
        <FieldGroup>
          <Field>
            <Label for="name-1">Name</Label>
            <Input id="name-1" name="name" @defaultValue="Pedro Duarte" />
          </Field>
          <Field>
            <Label for="username-1">Username</Label>
            <Input id="username-1" name="username" @defaultValue="@peduarte" />
          </Field>
        </FieldGroup>
        <d.Footer>
          <Button @variant="outline" {{d.close}}>Cancel</Button>
          <Button type="submit">Save changes</Button>
        </d.Footer>
      </d.Content>
    </form>
  </Dialog>
</template>
