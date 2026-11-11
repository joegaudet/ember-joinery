import { Menubar } from '@ember-joinery/ember'

<template>
  {{! As upstream's, the checkbox items keep the state they start with: a checkbox item's state
      is only ever @checked, which @onCheckedChange asks you to change. }}
  <Menubar class="w-72" as |bar|>
    <bar.Menu as |m|>
      <m.Trigger>View</m.Trigger>
      <m.Content class="w-64">
        <m.CheckboxItem>Always Show Bookmarks Bar</m.CheckboxItem>
        <m.CheckboxItem @checked={{true}}>
          Always Show Full URLs
        </m.CheckboxItem>
        <m.Separator />
        <m.Item @inset={{true}}>
          Reload
          <m.Shortcut>⌘R</m.Shortcut>
        </m.Item>
        <m.Item @disabled={{true}} @inset={{true}}>
          Force Reload
          <m.Shortcut>⇧⌘R</m.Shortcut>
        </m.Item>
      </m.Content>
    </bar.Menu>
    <bar.Menu as |m|>
      <m.Trigger>Format</m.Trigger>
      <m.Content>
        <m.CheckboxItem @checked={{true}}>Strikethrough</m.CheckboxItem>
        <m.CheckboxItem>Code</m.CheckboxItem>
        <m.CheckboxItem>Superscript</m.CheckboxItem>
      </m.Content>
    </bar.Menu>
  </Menubar>
</template>
