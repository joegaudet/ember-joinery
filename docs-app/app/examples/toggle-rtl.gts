import { Bookmark } from 'lucide'
import { Icon, Toggle } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream leaves the aria-label in English ("Toggle bookmark"); Joinery's is the
    Arabic it shows, so the name contains the visible text, as the audit every example runs
    asks. It's read aloud, not drawn, so the screenshot is the same.
  }}
  <Toggle aria-label="إشارة مرجعية" @size="sm" @variant="outline">
    <Icon @icon={{Bookmark}} class="group-aria-pressed/toggle:fill-foreground" />
    إشارة مرجعية
  </Toggle>
</template>
