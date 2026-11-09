import { Shadowed } from '@ember-joinery/primitives/shadowed'

<template>
  <style>
    p.shadow-demo {
      border: 1px solid;
      padding: 0.75rem;
      transform: skew(5deg, 5deg);
      width: 100px;
    }
  </style>

  <p class="shadow-demo">
    This element is affected by the global styles
  </p>

  <Shadowed>
    <p class="shadow-demo">
      This element is not affected by global sytles
    </p>
  </Shadowed>
</template>
