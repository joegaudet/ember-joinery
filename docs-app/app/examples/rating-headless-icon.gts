import type { TOC } from '@ember/component/template-only'
import { Rating, type RatingIconSignature } from '@ember-joinery/primitives/rating'

/** Each item's icon: its value, turned upside down while the rating reaches it. */
const Icon: TOC<RatingIconSignature> = <template>
  <div ...attributes class={{if @isSelected "rotate-180"}}>
    {{@value}}
  </div>
</template>

<template>
  {{!
    ember-primitives' "Custom Component / Icons" demo: a component as @icon, given each item's
    @value, @isSelected, @percentSelected and @readonly. Three differences, each for the audit:
    the rating is named (aria-label), the turn is a class rather than a style binding, and the
    picked items take the theme's --primary rather than gold, which is under 3:1 on white.
  }}
  <Rating @icon={{Icon}} aria-label="Rate it" class="rating-headless-icon" />
  <style>
    .rating-headless-icon {
      margin: 0;
      padding: 0;
      border: 0;
    }

    .rating-headless-icon > div {
      width: fit-content;
      display: grid;
      gap: 0.5rem;
      grid-auto-flow: column;
      justify-content: center;
      align-items: center;
      height: 4rem;
    }

    .rating-headless-icon [data-number] {
      font-size: 3rem;
      line-height: 1em;
      transition: all 0.1s;
      transform-origin: center;
      aspect-ratio: 1 / 1;
      user-select: none;
      width: 3rem;
      text-align: center;
      border-radius: 1.5rem;
      color: var(--muted-foreground);

      label:hover {
        cursor: pointer;
      }

      &:has(input:focus-visible) {
        box-shadow:
          0 0 0 2px var(--background),
          0 0 0 4px var(--ring);
        outline: 2px solid transparent;
        outline-offset: 2px;
      }

      input {
        appearance: none;
        position: absolute;

        &:focus-visible,
        &:focus {
          outline: none;
          box-shadow: none;
        }
      }

      &[data-selected] {
        color: var(--primary);
      }
    }

    .rating-headless-icon [data-number]:hover {
      transform: rotate3d(0, 0, 1, 15deg) scale(1.05);
    }
  </style>
</template>
