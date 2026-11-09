import { Link } from '@ember-joinery/primitives/link'
import { service } from '@ember-joinery/primitives/service'

/** This guide's pages are under its rootURL, which the router knows. */
const page = (rootURL: string, path: string) => `${rootURL}${path}`

<template>
  <style>
    @scope {
      /* A darker red than upstream's, so the text meets WCAG AA's contrast. */
      [data-active] {
        color: #c00;
      }
      a {
        padding: 0.25rem 0.5rem;
      }
    }
  </style>

  {{#let (service "router") as |router|}}
    <Link @href={{page router.rootURL "primitives/link.md"}}>
      This page
    </Link>
    |
    <Link @href={{page router.rootURL "primitives/proper-links.md"}}>
      Related page
    </Link>
  {{/let}}
</template>
