import { Breadcrumb } from '@ember-joinery/primitives/breadcrumb'

<template>
  <Breadcrumb class="breadcrumb-headless" as |b|>
    <li>
      <a href="/">Home</a>
    </li>
    <b.Separator>/</b.Separator>
    <li>
      <a href="/docs">Docs</a>
    </li>
    <b.Separator>/</b.Separator>
    <li aria-current="page">
      Breadcrumb
    </li>
  </Breadcrumb>
  <style>
    .breadcrumb-headless {
      font:
        0.875rem system-ui,
        sans-serif;
    }
    .breadcrumb-headless ol {
      display: flex;
      gap: 0.5rem;
      margin: 0;
      padding: 0;
      list-style: none;
    }
  </style>
</template>
