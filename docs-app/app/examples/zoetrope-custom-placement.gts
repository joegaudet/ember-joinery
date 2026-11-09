import { on } from '@ember/modifier'
import { Zoetrope } from '@ember-joinery/primitives/zoetrope'
import CardStyles from './zoetrope/card-styles.gts'

<template>
  <div class="zoetrope-example">
    <Zoetrope @gap={{8}} @offset={{40}}>
      <:header>
        <h2>Custom Placement</h2>
      </:header>

      <:controls as |z|>
        {{! Each button has a label, as "<" alone doesn't say what it does, and names its part,
            for the harness. }}
        <div class="my-controls">
          <button
            type="button"
            aria-label="Scroll left"
            data-test-jn-part="scroll-left"
            {{on "click" z.scrollLeft}}
            disabled={{z.cannotScrollLeft}}
          >&lt;</button>

          <button
            type="button"
            aria-label="Scroll right"
            data-test-jn-part="scroll-right"
            {{on "click" z.scrollRight}}
            disabled={{z.cannotScrollRight}}
          >&gt;</button>
        </div>
      </:controls>

      <:content>
        <a href="#" class="card">1</a>
        <a href="#" class="card">2</a>
        <a href="#" class="card">3</a>
        <a href="#" class="card">4</a>
        <a href="#" class="card">5</a>
        <a href="#" class="card">6</a>
        <a href="#" class="card">7</a>
        <a href="#" class="card">8</a>
        <a href="#" class="card">9</a>
        <a href="#" class="card">10</a>
        <a href="#" class="card">11</a>
        <a href="#" class="card">12</a>
      </:content>
    </Zoetrope>
  </div>

  <CardStyles />
  <style>
    /* Upstream's, with color: #fff added, so the arrows show on the dark buttons. */
    .my-controls {
      display: flex;
      position: absolute;
      top: 50%;
      transform: translateY(-50%);
      height: 40%;
      width: 100%;
      padding-top: 2rem;
      pointer-events: none;
    }
    .my-controls button {
      height: 100%;
      width: var(--zoetrope-offset);
      background: rgb(0 0 0 / 50%);
      color: #fff;
      pointer-events: auto;
    }
    .my-controls button:nth-child(2) {
      margin-left: auto;
    }
    .my-controls button:disabled {
      visibility: hidden;
    }
  </style>
</template>
