import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import { link } from '@ember-joinery/primitives/link'
import { service } from '@ember-joinery/primitives/service'

/**
 * A design system's link, on the helper: `aria-current` on the active one, a mark on
 * external ones, and the click routed (an app without `properLinks` needs that).
 */
const NavLink: TOC<{
  Element: HTMLAnchorElement
  Args: { href: string; activeOnSubPaths?: boolean }
  Blocks: { default: [] }
}> = <template>
  {{#let (link @href activeOnSubPaths=@activeOnSubPaths) as |l|}}
    <a
      href={{@href}}
      aria-current={{if l.isActive "page"}}
      target={{if l.isExternal "_blank"}}
      rel={{if l.isExternal "noopener noreferrer"}}
      data-test-jn-part="link"
      data-test-jn-value={{@href}}
      {{on "click" l.handleClick}}
      ...attributes
    >{{yield}}{{#if l.isExternal}} <span aria-hidden="true">↗</span>{{/if}}</a>
  {{/let}}
</template>

/** This guide's pages are under its rootURL, which the router knows. */
const page = (rootURL: string, path: string) => `${rootURL}${path}`

<template>
  {{#let (service "router") as |router|}}
    <nav aria-label="Routing utilities" data-test-jn="routing-nav">
      <ul>
        <li><NavLink @href={{page router.rootURL "primitives/link-helper.md"}}>Link helper</NavLink></li>
        <li><NavLink @href={{page router.rootURL "primitives/proper-links.md"}}>Proper links</NavLink></li>
        <li><NavLink @href={{page router.rootURL "primitives/query-params.md"}}>Query params</NavLink></li>
        <li>
          <NavLink
            @href="https://github.com/universal-ember/ember-primitives"
          >ember-primitives</NavLink>
        </li>
      </ul>
    </nav>
  {{/let}}
</template>
