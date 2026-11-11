import { Loader } from 'lucide'
import { Spinner } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's example redefines its Spinner around lucide's LoaderIcon. Joinery's Spinner is a
    package component rather than one copied into the app, so it takes the icon as @icon.
  }}
  <div class="flex items-center gap-4">
    <Spinner @icon={{Loader}} />
  </div>
</template>
