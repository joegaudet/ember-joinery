import { ArrowUpRight } from 'lucide'
import { Icon, asBadge } from '@ember-joinery/ember'

<template>
  {{!-- Upstream's <Badge asChild><a href="#link">: the asBadge modifier on your own link.
        With the router, it's <LinkTo @route="…" {{asBadge}}>. --}}
  <a href="#link" {{asBadge}}>
    Open Link
    <Icon @icon={{ArrowUpRight}} data-icon="inline-end" />
  </a>
</template>
