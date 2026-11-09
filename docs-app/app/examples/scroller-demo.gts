import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Scroller, type ScrollerControls } from '@ember-joinery/primitives/scroller'

// Set during render, as upstream's demo does, so the buttons outside the Scroller can call it.
let scrollers: ScrollerControls | undefined
const setScrollers = (s: ScrollerControls) => {
  scrollers = s
}
const click = (methodName: keyof ScrollerControls) => scrollers?.[methodName]()

/** Upstream fills the box with `lorem-ipsum`'s 10 random paragraphs; these are the classic ones. */
const LOREM = [
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
  'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
  'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
  'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.',
  'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.',
  'Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur.',
  'Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.',
  'At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.',
  'Similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio.',
  'Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.',
]

<template>
  <div class="demo" data-test-jn="scroller-demo">
    <Scroller class="scroll-container" as |s|>
      {{setScrollers s}}

      <div class="big-content">
        {{#each LOREM as |paragraph|}}<p>{{paragraph}}</p>{{/each}}
      </div>
    </Scroller>

    {{! The buttons' arrows are emoji, as upstream's; each has a label to say what it does, and
        a part and value (which upstream's don't have) for the test's harness. }}
    <div class="fixed-button-set">
      <button
        type="button"
        aria-label="Scroll to the left"
        data-test-jn-part="scroll-to"
        data-test-jn-value="left"
        {{on "click" (fn click "scrollToLeft")}}
      >⬅️</button>
      <button
        type="button"
        aria-label="Scroll to the bottom"
        data-test-jn-part="scroll-to"
        data-test-jn-value="bottom"
        {{on "click" (fn click "scrollToBottom")}}
      >⬇️</button>
      <button
        type="button"
        aria-label="Scroll to the top"
        data-test-jn-part="scroll-to"
        data-test-jn-value="top"
        {{on "click" (fn click "scrollToTop")}}
      >⬆️</button>
      <button
        type="button"
        aria-label="Scroll to the right"
        data-test-jn-part="scroll-to"
        data-test-jn-value="right"
        {{on "click" (fn click "scrollToRight")}}
      >➡️</button>
    </div>
  </div>

  <style>
    .demo {
      position: relative;
    }
    /* Upstream's .container, renamed: Tailwind, which the guide's examples use, has its own. */
    .scroll-container {
      overflow: auto;
      height: 200px;
      scroll-behavior: smooth;
    }
    .big-content {
      width: 200%;
    }
    /* Upstream lifts these above its preview (margin-top: -4rem); here they sit at its corner. */
    .fixed-button-set {
      position: absolute;
      top: 0rem;
      right: 0rem;
      filter: drop-shadow(0 2px 3px #555);
    }
    .fixed-button-set button {
      padding: 0;
      font-size: 2rem;
      line-height: 2rem;
      background: none;
      border: 0;
    }
  </style>
</template>
