import { Rating } from '@ember-joinery/primitives/rating'

<template>
  {{!
    ember-primitives' "non-interactive (display-only) mode" demo: a rating that says its value
    for assistive technology (Rated 2 out of 5), one that shows it in its label block, and one
    whose own block lays out rating.Stars beside it. Two differences, each for the audit: the
    radios are visually hidden rather than display: none, so each item keeps its name, and the
    picked items take the theme's --primary rather than gold, which is under 3:1 on white.
  }}
  <div class="rating-headless-display">
    <Rating @value={{2}} @interactive={{false}} />
    <Rating @value={{4}} @interactive={{false}}>
      <:label as |rating|>
        {{rating.value}}
        of
        {{rating.total}}
      </:label>
    </Rating>
    <Rating @value={{3}} @interactive={{false}} as |rating|>
      <rating.Stars />
      {{rating.value}}
      of
      {{rating.total}}
    </Rating>
  </div>
  <style>
    .rating-headless-display > fieldset {
      width: fit-content;
      display: grid;
      gap: 0.5rem;
      grid-auto-flow: column;
      justify-content: center;
      align-items: center;
      height: 4rem;
      margin: 0;
      padding: 0;
      border: 0;
    }

    .rating-headless-display [data-number] {
      font-size: 3rem;
      line-height: 3rem;
      transition: all 0.1s;
      transform-origin: center;
      aspect-ratio: 1 / 1;
      cursor: pointer;
      user-select: none;
      color: var(--muted-foreground);

      input {
        position: absolute;
        width: 1px;
        height: 1px;
        margin: -1px;
        overflow: hidden;
        clip-path: inset(50%);
        white-space: nowrap;
      }

      &[data-selected] {
        color: var(--primary);
      }
    }

    .rating-headless-display [data-number]:hover {
      transform: rotate3d(0, 0, 1, 15deg) scale(1.05);
    }
  </style>
</template>
