import { Zoetrope } from '@ember-joinery/primitives/zoetrope'
import CardStyles from './zoetrope/card-styles.gts'

<template>
  <div class="zoetrope-example">
    <Zoetrope @gap={{8}} @offset={{40}} @scrollBehavior="instant">
      <:header>
        <h2>Instant Scroll</h2>
      </:header>

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
