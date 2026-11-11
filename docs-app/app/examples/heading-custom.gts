import Component from '@glimmer/component'
import { As } from '@ember-joinery/primitives/as'
import { getSectionHeadingLevel } from '@ember-joinery/primitives/heading'

/**
 * Upstream's own heading, written on `getSectionHeadingLevel`, as its Heading Level page shows
 * it. It picks the tag with `As` (upstream: ember-element-helper's `element`), which works on
 * every Ember Joinery supports.
 */
class MyHeading extends Component<{ Element: HTMLHeadingElement; Blocks: { default: [] } }> {
  markerNode = document.createTextNode('')

  get hLevel() {
    return `h${getSectionHeadingLevel(this.markerNode)}`
  }

  <template>
    {{this.markerNode}}

    <As @as={{this.hLevel}} ...attributes>
      {{yield}}
    </As>
  </template>
}

// Usage / output
//
// Upstream runs this in a REPL, a page of its own, where the first heading is an h1. Here it is
// on the guide's page, so it sits in a section, as the Heading demo does: its headings carry on
// from the page's, and the page keeps its one h1. On its own it starts at h1.
<template>
  <section aria-label="heading-custom" class="heading-custom">
    <MyHeading>hello there</MyHeading>

    <section>
      <MyHeading>hello there</MyHeading>
    </section>
  </section>

  <style>
    /* These styles are completely optional */
    .heading-custom :is(h1, h2, h3, h4, h5, h6) {
      margin: 0;
      position: relative;
    }

    .heading-custom :is(h1, h2, h3, h4, h5, h6)::before {
      position: absolute;
      margin-left: -1.2em;
      font-size: 0.7em;
      text-align: right;
      opacity: 0.8;
    }

    .heading-custom h1 {
      font-size: 2.5rem;
    }
    .heading-custom h2 {
      font-size: 2.25rem;
    }
    .heading-custom h3 {
      font-size: 2rem;
    }
    .heading-custom h4 {
      font-size: 1.5rem;
    }
    .heading-custom h5 {
      font-size: 1.25rem;
    }
    .heading-custom h6 {
      font-size: 1rem;
    }

    .heading-custom h1::before {
      content: "h1";
    }
    .heading-custom h2::before {
      content: "h2";
    }
    .heading-custom h3::before {
      content: "h3";
    }
    .heading-custom h4::before {
      content: "h4";
    }
    .heading-custom h5::before {
      content: "h5";
    }
    .heading-custom h6::before {
      content: "h6";
    }

    .heading-custom {
      padding-left: 2rem;
    }
    .heading-custom section {
      border: 1px dotted;
      padding: 0.25rem 0.5rem 0.25rem 2rem;
      position: relative;
    }
  </style>
</template>
