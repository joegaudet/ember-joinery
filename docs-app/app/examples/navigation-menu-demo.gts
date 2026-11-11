import type { TOC } from '@ember/component/template-only'
import { NavigationMenu, navigationMenuTriggerStyle } from '@ember-joinery/ember'
import type { NavigationMenuBlockParams } from '@ember-joinery/ember'

const components: { title: string; href: string; description: string }[] = [
  {
    title: 'Alert Dialog',
    href: '/docs/primitives/alert-dialog',
    description:
      'A modal dialog that interrupts the user with important content and expects a response.',
  },
  {
    title: 'Hover Card',
    href: '/docs/primitives/hover-card',
    description: 'For sighted users to preview content available behind a link.',
  },
  {
    title: 'Progress',
    href: '/docs/primitives/progress',
    description:
      'Displays an indicator showing the completion progress of a task, typically displayed as a progress bar.',
  },
  {
    title: 'Scroll-area',
    href: '/docs/primitives/scroll-area',
    description: 'Visually or semantically separates content.',
  },
  {
    title: 'Tabs',
    href: '/docs/primitives/tabs',
    description:
      'A set of layered sections of content—known as tab panels—that are displayed one at a time.',
  },
  {
    title: 'Tooltip',
    href: '/docs/primitives/tooltip',
    description:
      'A popup that displays information related to an element when the element receives keyboard focus or the mouse hovers over it.',
  },
]

/** Upstream's `ListItem`: a link with a title and a line or two of description. */
const ListItem: TOC<{
  Args: { Link: NavigationMenuBlockParams['Link']; href: string; title: string }
  Blocks: { default: [] }
  Element: HTMLLIElement
}> = <template>
  <li ...attributes>
    <@Link href={{@href}}>
      <div class="flex flex-col gap-1 text-sm">
        <div class="leading-none font-medium">{{@title}}</div>
        <div class="line-clamp-2 text-muted-foreground">{{yield}}</div>
      </div>
    </@Link>
  </li>
</template>

<template>
  <NavigationMenu as |n|>
    <n.List>
      <n.Item as |item|>
        <item.Trigger>Getting started</item.Trigger>
        <item.Content>
          <ul class="w-96">
            <ListItem @Link={{n.Link}} @href="/docs" @title="Introduction">
              Re-usable components built with Tailwind CSS.
            </ListItem>
            <ListItem @Link={{n.Link}} @href="/docs/installation" @title="Installation">
              How to install dependencies and structure your app.
            </ListItem>
            <ListItem @Link={{n.Link}} @href="/docs/primitives/typography" @title="Typography">
              Styles for headings, paragraphs, lists...etc
            </ListItem>
          </ul>
        </item.Content>
      </n.Item>
      <n.Item class="hidden md:flex" as |item|>
        <item.Trigger>Components</item.Trigger>
        <item.Content>
          <ul class="grid w-[400px] gap-2 md:w-[500px] md:grid-cols-2 lg:w-[600px]">
            {{#each components as |entry|}}
              <ListItem @Link={{n.Link}} @title={{entry.title}} @href={{entry.href}}>
                {{entry.description}}
              </ListItem>
            {{/each}}
          </ul>
        </item.Content>
      </n.Item>
      <n.Item>
        <n.Link href="/docs" class={{(navigationMenuTriggerStyle)}}>Docs</n.Link>
      </n.Item>
    </n.List>
  </NavigationMenu>
</template>
