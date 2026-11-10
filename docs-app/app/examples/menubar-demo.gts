import { Menubar } from '@ember-joinery/ember'

<template>
  <Menubar class="w-72" as |bar|>
    <bar.Menu as |m|>
      <m.Trigger>File</m.Trigger>
      <m.Content>
        <m.Group>
          <m.Item>
            New Tab
            <m.Shortcut>⌘T</m.Shortcut>
          </m.Item>
          <m.Item>
            New Window
            <m.Shortcut>⌘N</m.Shortcut>
          </m.Item>
          <m.Item @disabled={{true}}>New Incognito Window</m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Sub as |s|>
            <s.Trigger>Share</s.Trigger>
            <s.Content>
              <m.Group>
                <m.Item>Email link</m.Item>
                <m.Item>Messages</m.Item>
                <m.Item>Notes</m.Item>
              </m.Group>
            </s.Content>
          </m.Sub>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item>
            Print...
            <m.Shortcut>⌘P</m.Shortcut>
          </m.Item>
        </m.Group>
      </m.Content>
    </bar.Menu>
    <bar.Menu as |m|>
      <m.Trigger>Edit</m.Trigger>
      <m.Content>
        <m.Group>
          <m.Item>
            Undo
            <m.Shortcut>⌘Z</m.Shortcut>
          </m.Item>
          <m.Item>
            Redo
            <m.Shortcut>⇧⌘Z</m.Shortcut>
          </m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Sub as |s|>
            <s.Trigger>Find</s.Trigger>
            <s.Content>
              <m.Group>
                <m.Item>Search the web</m.Item>
              </m.Group>
              <m.Separator />
              <m.Group>
                <m.Item>Find...</m.Item>
                <m.Item>Find Next</m.Item>
                <m.Item>Find Previous</m.Item>
              </m.Group>
            </s.Content>
          </m.Sub>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item>Cut</m.Item>
          <m.Item>Copy</m.Item>
          <m.Item>Paste</m.Item>
        </m.Group>
      </m.Content>
    </bar.Menu>
    <bar.Menu as |m|>
      <m.Trigger>View</m.Trigger>
      <m.Content class="w-44">
        {{! As upstream's, these two keep the state they start with: a checkbox item's state is
            only ever @checked, which @onCheckedChange asks you to change. }}
        <m.Group>
          <m.CheckboxItem>Bookmarks Bar</m.CheckboxItem>
          <m.CheckboxItem @checked={{true}}>Full URLs</m.CheckboxItem>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item @inset={{true}}>
            Reload
            <m.Shortcut>⌘R</m.Shortcut>
          </m.Item>
          <m.Item @disabled={{true}} @inset={{true}}>
            Force Reload
            <m.Shortcut>⇧⌘R</m.Shortcut>
          </m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item @inset={{true}}>Toggle Fullscreen</m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item @inset={{true}}>Hide Sidebar</m.Item>
        </m.Group>
      </m.Content>
    </bar.Menu>
    <bar.Menu as |m|>
      <m.Trigger>Profiles</m.Trigger>
      <m.Content>
        <m.RadioGroup @value="benoit" as |g|>
          <g.Item @value="andy">Andy</g.Item>
          <g.Item @value="benoit">Benoit</g.Item>
          <g.Item @value="Luis">Luis</g.Item>
        </m.RadioGroup>
        <m.Separator />
        <m.Group>
          <m.Item @inset={{true}}>Edit...</m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item @inset={{true}}>Add Profile...</m.Item>
        </m.Group>
      </m.Content>
    </bar.Menu>
  </Menubar>
</template>
