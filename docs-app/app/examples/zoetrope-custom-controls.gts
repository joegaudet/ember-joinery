import { on } from '@ember/modifier'
import { Zoetrope } from '@ember-joinery/primitives/zoetrope'
import CardStyles from './zoetrope/card-styles.gts'

<template>
  <div class="zoetrope-example">
    <Zoetrope @gap={{8}} @offset={{40}}>
      <:header>
        <h2>Default Placement</h2>
      </:header>

      <:controls as |z|>
        {{! data-jn-zoetrope-controls places them where the default controls go. Each button has a label, as
            "<" alone doesn't say what it does, and names its part, for the harness. }}
        <div data-jn-zoetrope-controls>
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
</template>
