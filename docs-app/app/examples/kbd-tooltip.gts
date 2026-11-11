import { Button, ButtonGroup, Kbd, KbdGroup, Tooltip } from '@ember-joinery/ember'

<template>
  <div class="flex flex-wrap gap-4">
    <ButtonGroup>
      <Tooltip as |t|>
        <Button @variant="outline" {{t.trigger}}>Save</Button>
        <t.Content>
          Save Changes
          <Kbd>S</Kbd>
        </t.Content>
      </Tooltip>
      <Tooltip as |t|>
        <Button @variant="outline" {{t.trigger}}>Print</Button>
        <t.Content>
          Print Document
          <KbdGroup>
            <Kbd>Ctrl</Kbd>
            <Kbd>P</Kbd>
          </KbdGroup>
        </t.Content>
      </Tooltip>
    </ButtonGroup>
  </div>
</template>
