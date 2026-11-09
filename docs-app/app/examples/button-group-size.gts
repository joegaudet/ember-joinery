import { Plus } from 'lucide'
import { Button, ButtonGroup, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's icon buttons have no labels; an icon-only button needs one, so these are named. }}
  <div class="flex flex-col items-start gap-8">
    <ButtonGroup>
      <Button @variant="outline" @size="sm">
        Small
      </Button>
      <Button @variant="outline" @size="sm">
        Button
      </Button>
      <Button @variant="outline" @size="sm">
        Group
      </Button>
      <Button @variant="outline" @size="icon-sm" aria-label="Add">
        <Icon @icon={{Plus}} />
      </Button>
    </ButtonGroup>
    <ButtonGroup>
      <Button @variant="outline">Default</Button>
      <Button @variant="outline">Button</Button>
      <Button @variant="outline">Group</Button>
      <Button @variant="outline" @size="icon" aria-label="Add">
        <Icon @icon={{Plus}} />
      </Button>
    </ButtonGroup>
    <ButtonGroup>
      <Button @variant="outline" @size="lg">
        Large
      </Button>
      <Button @variant="outline" @size="lg">
        Button
      </Button>
      <Button @variant="outline" @size="lg">
        Group
      </Button>
      <Button @variant="outline" @size="icon-lg" aria-label="Add">
        <Icon @icon={{Plus}} />
      </Button>
    </ButtonGroup>
  </div>
</template>
