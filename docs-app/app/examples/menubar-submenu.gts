import { Menubar } from '@ember-joinery/ember'

<template>
  <Menubar class="w-72" as |bar|>
    <bar.Menu as |m|>
      <m.Trigger>File</m.Trigger>
      <m.Content>
        <m.Sub as |s|>
          <s.Trigger>Share</s.Trigger>
          <s.Content>
            <m.Item>Email link</m.Item>
            <m.Item>Messages</m.Item>
            <m.Item>Notes</m.Item>
          </s.Content>
        </m.Sub>
        <m.Separator />
        <m.Item>
          Print...
          <m.Shortcut>⌘P</m.Shortcut>
        </m.Item>
      </m.Content>
    </bar.Menu>
    <bar.Menu as |m|>
      <m.Trigger>Edit</m.Trigger>
      <m.Content>
        <m.Item>
          Undo
          <m.Shortcut>⌘Z</m.Shortcut>
        </m.Item>
        <m.Item>
          Redo
          <m.Shortcut>⇧⌘Z</m.Shortcut>
        </m.Item>
        <m.Separator />
        <m.Sub as |s|>
          <s.Trigger>Find</s.Trigger>
          <s.Content>
            <m.Item>Find...</m.Item>
            <m.Item>Find Next</m.Item>
            <m.Item>Find Previous</m.Item>
          </s.Content>
        </m.Sub>
        <m.Separator />
        <m.Item>Cut</m.Item>
        <m.Item>Copy</m.Item>
        <m.Item>Paste</m.Item>
      </m.Content>
    </bar.Menu>
  </Menubar>
</template>
