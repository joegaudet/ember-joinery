import { Link } from '@ember-joinery/primitives/link'

<template>
  <Link @href="/">Home</Link>
  &nbsp;&nbsp;

  <Link @href="https://developer.mozilla.org" as |a|>
    MDN

    {{#if a.isExternal}}
      ➚
    {{/if}}
  </Link>
</template>
