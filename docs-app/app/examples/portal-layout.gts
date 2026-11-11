import type { TOC } from '@ember/component/template-only'
import { Portal } from '@ember-joinery/primitives/portal'

// Upstream declares these after the layout with `var`, so the layout reads first; here they
// come first, as `const`, which the lint asks for.
const ExampleA: TOC<object> = <template>
  <Portal @to=".main-container" @append={{true}}>
    ExampleA main
  </Portal>
  <Portal @to=".header-container" @append={{true}}>
    ExampleA header
  </Portal>
  <Portal @to=".sidebar-container" @append={{true}}>
    ExampleA sidebar
  </Portal>
</template>

const ExampleB: TOC<object> = <template>
  <Portal @to=".main-container" @append={{true}}>
    ExampleB main
  </Portal>
  <Portal @to=".sidebar-container" @append={{true}}>
    ExampleB sidebar
  </Portal>
  <Portal @to=".footer-container" @append={{true}}>
    ExampleB footer
  </Portal>
</template>

<template>
  <div class="layout">
    <div class="header-container"></div>
    <div class="main-container"></div>
    <div class="sidebar-container"></div>
    <div class="footer-container"></div>
  </div>

  <ExampleA />
  <ExampleB />
  {{! or yield or outlet }}

  <style>
    .header-container {
      grid-area: header;
    }
    .main-container {
      grid-area: main;
    }
    .sidebar-container {
      grid-area: sidebar;
    }
    .footer-container {
      grid-area: footer;
    }
    .layout {
      display: grid;
      grid-template-columns: 1fr 1fr 50px 1fr;
      grid-template-rows: auto;
      grid-template-areas:
        "header header header header"
        "main main . sidebar"
        "footer footer footer footer";
      gap: 0.5rem;
    }

    .header-container,
    .main-container,
    .sidebar-container,
    .footer-container {
      border: 1px solid;
    }
  </style>
</template>
