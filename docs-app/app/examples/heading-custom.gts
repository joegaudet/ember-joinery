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
<template>
  <div class="heading-custom">
    <MyHeading>hello there</MyHeading>

    <section>
      <MyHeading>hello there</MyHeading>
    </section>
  </div>

  <style>
    /* These styles are completely optional */
    .heading-custom h1,
    .heading-custom h2 {
      margin: 0;
      position: relative;
    }

    .heading-custom h1::before,
    .heading-custom h2::before {
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

    .heading-custom h1::before {
      content: "h1";
    }
    .heading-custom h2::before {
      content: "h2";
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
