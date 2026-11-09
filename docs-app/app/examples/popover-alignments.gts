import { Button, Popover } from '@ember-joinery/ember'

<template>
  <div class="flex gap-6">
    <Popover as |p|>
      <Button @variant="outline" @size="sm" {{p.trigger}}>
        Start
      </Button>
      <p.Content @align="start" class="w-40">
        Aligned to start
      </p.Content>
    </Popover>
    <Popover as |p|>
      <Button @variant="outline" @size="sm" {{p.trigger}}>
        Center
      </Button>
      <p.Content @align="center" class="w-40">
        Aligned to center
      </p.Content>
    </Popover>
    <Popover as |p|>
      <Button @variant="outline" @size="sm" {{p.trigger}}>
        End
      </Button>
      <p.Content @align="end" class="w-40">
        Aligned to end
      </p.Content>
    </Popover>
  </div>
</template>
