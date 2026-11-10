import { File, Folder, HelpCircle, Save, Settings, Trash } from 'lucide'
import { Icon, Menubar } from '@ember-joinery/ember'

<template>
  <Menubar class="w-72" as |bar|>
    <bar.Menu as |m|>
      <m.Trigger>File</m.Trigger>
      <m.Content>
        <m.Item>
          <Icon @icon={{File}} />
          New File
          <m.Shortcut>⌘N</m.Shortcut>
        </m.Item>
        <m.Item>
          <Icon @icon={{Folder}} />
          Open Folder
        </m.Item>
        <m.Separator />
        <m.Item>
          <Icon @icon={{Save}} />
          Save
          <m.Shortcut>⌘S</m.Shortcut>
        </m.Item>
      </m.Content>
    </bar.Menu>
    <bar.Menu as |m|>
      <m.Trigger>More</m.Trigger>
      <m.Content>
        <m.Group>
          <m.Item>
            <Icon @icon={{Settings}} />
            Settings
          </m.Item>
          <m.Item>
            <Icon @icon={{HelpCircle}} />
            Help
          </m.Item>
          <m.Separator />
          <m.Item @variant="destructive">
            <Icon @icon={{Trash}} />
            Delete
          </m.Item>
        </m.Group>
      </m.Content>
    </bar.Menu>
  </Menubar>
</template>
