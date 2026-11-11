import { htmlSafe } from '@ember/template'
import { Progress } from '@ember-joinery/primitives/progress'

/** The bar's width: a number the progress bar computes, so it is safe to bind as a style. */
const width = (percent: number) => htmlSafe(`width: ${percent}%`)

const filesLabel = (value: number, max: number) => `${value} of ${max} files`

<template>
  <div class="progress-headless">
    <Progress
      @value={{7}}
      @max={{12}}
      @getValueLabel={{filesLabel}}
      aria-label="Upload"
      class="progress-headless-track"
      as |p|
    >
      <p.Indicator class="progress-headless-bar" style={{width p.percent}} />
    </Progress>
    <span>{{filesLabel 7 12}}</span>
  </div>
  <style>
    .progress-headless {
      display: grid;
      gap: 0.75rem;
      width: 16rem;
      font:
        0.875rem system-ui,
        sans-serif;
    }
    .progress-headless-track {
      height: 0.5rem;
      border-radius: 9999px;
      background: #e5e5e5;
      overflow: hidden;
    }
    .progress-headless-bar {
      height: 100%;
      background: #171717;
      transition: width 150ms;
    }
  </style>
</template>
