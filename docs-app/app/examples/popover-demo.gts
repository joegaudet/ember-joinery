import { Button, Input, Label, Popover } from '@ember-joinery/ember'

<template>
  {{! Named popover, not p: a block param named p would turn the <p> below into a call to it. }}
  <Popover as |popover|>
    <Button @variant="outline" {{popover.trigger}}>Open popover</Button>
    <popover.Content class="w-80">
      <div class="grid gap-4">
        <div class="space-y-2">
          <h4 class="leading-none font-medium">Dimensions</h4>
          <p class="text-sm text-muted-foreground">
            Set the dimensions for the layer.
          </p>
        </div>
        <div class="grid gap-2">
          <div class="grid grid-cols-3 items-center gap-4">
            <Label for="width">Width</Label>
            <Input id="width" @defaultValue="100%" class="col-span-2 h-8" />
          </div>
          <div class="grid grid-cols-3 items-center gap-4">
            <Label for="maxWidth">Max. width</Label>
            <Input id="maxWidth" @defaultValue="300px" class="col-span-2 h-8" />
          </div>
          <div class="grid grid-cols-3 items-center gap-4">
            <Label for="height">Height</Label>
            <Input id="height" @defaultValue="25px" class="col-span-2 h-8" />
          </div>
          <div class="grid grid-cols-3 items-center gap-4">
            <Label for="maxHeight">Max. height</Label>
            <Input id="maxHeight" @defaultValue="none" class="col-span-2 h-8" />
          </div>
        </div>
      </div>
    </popover.Content>
  </Popover>
</template>
