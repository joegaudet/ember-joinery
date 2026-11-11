import { FileText, GitBranch, Search } from 'lucide'
import { Icon, Marker } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-3 py-12">
    <Marker @variant="border" as |m|>
      <m.Icon>
        <Icon @icon={{GitBranch}} />
      </m.Icon>
      <m.Content>Switched to release-candidate</m.Content>
    </Marker>
    <Marker @variant="border" as |m|>
      <m.Icon>
        <Icon @icon={{Search}} />
      </m.Icon>
      <m.Content>Reviewed 8 related files</m.Content>
    </Marker>
    <Marker @variant="border" as |m|>
      <m.Icon>
        <Icon @icon={{FileText}} />
      </m.Icon>
      <m.Content>Opened implementation notes</m.Content>
    </Marker>
  </div>
</template>
