import { Save } from 'lucide'
import { Button, Icon, Kbd, Tooltip } from '@ember-joinery/ember'

<template>
  <Tooltip as |t|>
    {{! Upstream leaves the icon button unnamed; it gets aria-label, so the audit passes. The
        tooltip describes it, with its shortcut. }}
    <Button @variant="outline" @size="icon-sm" aria-label="Save Changes" {{t.trigger}}>
      <Icon @icon={{Save}} />
    </Button>
    <t.Content>
      Save Changes
      <Kbd>S</Kbd>
    </t.Content>
  </Tooltip>
</template>
