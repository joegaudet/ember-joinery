import { AudioLines, Plus } from 'lucide'
import { Button, ButtonGroup, Icon, InputGroup, Tooltip } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's icon button and input have no names, but for the input's placeholder; these are
    named (aria-label), so the audit passes. The addon is the tooltip's trigger, as upstream's
    TooltipTrigger asChild makes it.
  }}
  <ButtonGroup>
    <ButtonGroup>
      <Button @variant="outline" @size="icon" aria-label="Add">
        <Icon @icon={{Plus}} />
      </Button>
    </ButtonGroup>
    <ButtonGroup>
      <InputGroup as |g|>
        <g.Input placeholder="Send a message..." aria-label="Message" />
        <Tooltip as |t|>
          <g.Addon @align="inline-end" {{t.trigger}}>
            <Icon @icon={{AudioLines}} />
          </g.Addon>
          <t.Content>Voice Mode</t.Content>
        </Tooltip>
      </InputGroup>
    </ButtonGroup>
  </ButtonGroup>
</template>
