import { on } from '@ember/modifier'
import { GitBranch, RotateCcw } from 'lucide'
import { Icon, Marker, toast } from '@ember-joinery/ember'

const revert = () => toast('You clicked the revert button')

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Marker @as="a" href="#links-and-buttons" as |m|>
      <m.Icon>
        <Icon @icon={{GitBranch}} />
      </m.Icon>
      <m.Content>View the pull request</m.Content>
    </Marker>
    <Marker
      @as="button"
      type="button"
      class="transition-colors hover:text-foreground"
      {{on "click" revert}}
      as |m|
    >
      <m.Icon>
        <Icon @icon={{RotateCcw}} />
      </m.Icon>
      <m.Content>Revert this change</m.Content>
    </Marker>
  </div>
</template>
