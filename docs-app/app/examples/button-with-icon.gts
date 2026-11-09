import { GitBranch } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's draws Tabler's git-branch; Joinery's icons are lucide's. }}
  <Button @variant="outline" @size="sm">
    <Icon @icon={{GitBranch}} />
    New Branch
  </Button>
</template>
