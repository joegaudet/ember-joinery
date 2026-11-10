import { Circle, CircleAlert, CircleCheck, LoaderCircle } from 'lucide'
import { Icon, Trace, TraceLine } from '@ember-joinery/ember'

<template>
  <Trace class="max-w-sm">
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{CircleCheck}} />
      </l.Icon>
      <l.Title>Ran pnpm install</l.Title>
    </TraceLine>
    <TraceLine @status="error" as |l|>
      <l.Icon>
        <Icon @icon={{CircleAlert}} />
      </l.Icon>
      <l.Title>Failed to run pnpm lint</l.Title>
    </TraceLine>
    <TraceLine @status="running" as |l|>
      <l.Icon>
        <Icon @icon={{LoaderCircle}} class="animate-spin" />
      </l.Icon>
      <l.Title>Running pnpm build</l.Title>
    </TraceLine>
    <TraceLine @status="pending" as |l|>
      <l.Icon>
        <Icon @icon={{Circle}} />
      </l.Icon>
      <l.Title>Run pnpm test</l.Title>
    </TraceLine>
  </Trace>
</template>
