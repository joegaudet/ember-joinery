/**
 * The cards in the Zoetrope examples, from the `<style>` on upstream's page. The colours are
 * darker than upstream's (red, yellow, orange, pink…), so the white text on them meets WCAG
 * AA's contrast, which every example's test audits.
 */
<template>
  <style>
    .zoetrope-example h2 {
      margin: 0;
    }
    .zoetrope-example .card {
      background: #b00020;
      color: #fff;
      display: block;
      height: 150px;
      padding: 24px;
      text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.5);
      width: 200px;
    }
    .zoetrope-example .card:nth-child(1n) {
      background: #1d4ed8;
    }
    .zoetrope-example .card:nth-child(2n) {
      background: #15803d;
    }
    .zoetrope-example .card:nth-child(3n) {
      background: #854d0e;
    }
    .zoetrope-example .card:nth-child(4n) {
      background: #7e22ce;
    }
    .zoetrope-example .card:nth-child(5n) {
      background: #c2410c;
    }
    .zoetrope-example .card:nth-child(6n) {
      background: #be185d;
    }
    .zoetrope-example .card:nth-child(7n) {
      background: #7c2d12;
    }
    .zoetrope-example .card:nth-child(8n) {
      background: #000;
    }
    .zoetrope-example .card:nth-child(9n) {
      background: #0f766e;
    }
    .zoetrope-example .card:nth-child(10n) {
      background: #4b5563;
    }
  </style>
</template>
