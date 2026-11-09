import { Heading } from '@ember-joinery/primitives/heading'
import { InViewport } from '@ember-joinery/primitives/viewport'

/**
 * Where upstream's demo has a `<main aria-label="heading-demo">`, this has a `<section>` with
 * the same label: the guide's page has its own `<main>`, and a page has one. A section is a
 * boundary for the level search too, so on the guide's page the demo's headings start below
 * the page's own, as upstream's do. Upstream's text is white, for its dark site; here it takes
 * the preview's colour.
 */
<template>
  <InViewport style="min-height:300px;">
    <section aria-label="heading-demo" class="heading-demo not-prose">
      <Heading>a heading</Heading>

      <nav>
        <Heading>a heading</Heading>
      </nav>

      <article>
        <Heading>a heading</Heading>
        <a href="#">
          <Heading>a heading</Heading>
        </a>
        <section>
          <Heading>a heading</Heading>
          <article>
            <Heading>a heading</Heading>
          </article>
        </section>
        <footer>
          <Heading>a heading</Heading>

        </footer>
      </article>
    </section>
  </InViewport>

  <style>
    @scope {
      h1,
      h2,
      h3,
      h4,
      h5,
      h6 {
        margin-top: 0;
        margin-bottom: 0;
        color: inherit;
      }

      h1::before,
      h2::before,
      h3::before,
      h4::before,
      h5::before,
      h6::before {
        position: absolute;
        margin-left: -1.2em;
        font-size: 0.7em;
        text-align: right;
        opacity: 0.8;
      }

      h1 {
        font-size: 2.5rem;
      }
      h2 {
        font-size: 2.25rem;
      }
      h3 {
        font-size: 2rem;
      }
      h4 {
        font-size: 1.5rem;
      }
      h5 {
        font-size: 1.25rem;
      }
      h6 {
        font-size: 1rem;
      }
      a {
        color: inherit;
      }

      h1::before {
        content: "h1";
      }
      h2::before {
        content: "h2";
      }
      h3::before {
        content: "h3";
      }
      h4::before {
        content: "h4";
      }
      h5::before {
        content: "h5";
      }
      h6::before {
        content: "h6";
      }

      article,
      section,
      aside,
      nav,
      footer {
        border: 1px dotted;
        padding: 0.25rem 1.5rem;
        padding-left: 2rem;
        padding-right: 0.5rem;
        position: relative;

        &::before {
          position: absolute;
          right: 0.5rem;
          top: -1rem;
          font-size: 0.7rem;
          text-align: right;
          opacity: 0.8;
        }
      }

      section,
      article {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
      }

      article::before {
        content: "<article>";
      }
      section::before {
        content: "<section>";
      }
      aside::before {
        content: "<aside>";
      }
      nav::before {
        content: "<nav>";
      }
      footer::before {
        content: "<footer>";
      }

      .heading-demo {
        display: grid;
        gap: 2.5rem;
        grid-template-columns: max-content 1fr;
        grid-template-areas:
          "heading heading"
          "nav content"
          "nav content"
          "nav content";
      }

      .heading-demo > :first-child {
        grid-area: heading;
      }
      nav {
        grid-area: nav;
      }
      article {
        grid-area: content;
      }
    }
  </style>
</template>
