import { fn } from '@ember/helper'
import { Moon, Sun } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'
import { ColorScheme } from '@ember-joinery/primitives/color-scheme'
import { service } from '@ember-joinery/primitives/service'

/**
 * shadcn's mode toggle (`components/mode-toggle.tsx` on its dark mode pages), on Joinery's
 * color scheme instead of a theme provider: light, dark or the system's, saved for the next
 * visit. Choosing one changes the whole page, as it would in your app.
 */
<template>
  {{#let (service ColorScheme) as |scheme|}}
    <DropdownMenu as |m|>
      <Button @variant="outline" @size="icon" {{m.trigger}}>
        <Icon
          @icon={{Sun}}
          class="h-[1.2rem] w-[1.2rem] scale-100 rotate-0 transition-all dark:scale-0 dark:-rotate-90"
        />
        <Icon
          @icon={{Moon}}
          class="absolute h-[1.2rem] w-[1.2rem] scale-0 rotate-90 transition-all dark:scale-100 dark:rotate-0"
        />
        <span class="sr-only">Toggle theme</span>
      </Button>
      <m.Content @align="end">
        <m.Item @onSelect={{fn scheme.set "light"}}>
          Light
        </m.Item>
        <m.Item @onSelect={{fn scheme.set "dark"}}>
          Dark
        </m.Item>
        <m.Item @onSelect={{fn scheme.set "system"}}>
          System
        </m.Item>
      </m.Content>
    </DropdownMenu>
  {{/let}}
</template>
