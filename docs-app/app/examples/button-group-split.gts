import { Plus } from 'lucide'
import { Button, ButtonGroup, Icon } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's draws Tabler's plus; Joinery's icons are lucide's, whose plus is the same two
    strokes. Upstream's icon button has no label; an icon-only button needs one, so this one is
    named.
  }}
  <ButtonGroup as |g|>
    <Button @variant="secondary">Button</Button>
    <g.Separator />
    <Button @size="icon" @variant="secondary" aria-label="Add">
      <Icon @icon={{Plus}} />
    </Button>
  </ButtonGroup>
</template>
