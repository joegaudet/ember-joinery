import { Accordion } from '@ember-joinery/primitives/accordion'

const questions = [
  {
    value: 'accessible',
    question: 'Is it accessible?',
    answer: 'Yes. It follows the WAI-ARIA accordion pattern.',
  },
  {
    value: 'styled',
    question: 'Is it styled?',
    answer: 'No. It has no styles: bring your own, or use the styled Accordion.',
  },
  {
    value: 'animated',
    question: 'Can it be animated?',
    answer: 'Yes. Its content is measured into a CSS variable for your animation to use.',
  },
]

<template>
  <Accordion @type="single" @collapsible={{true}} class="faq" as |accordion|>
    {{#each questions as |q|}}
      <accordion.Item @value={{q.value}} class="faq-item" as |item|>
        <item.Header class="faq-header" as |header|>
          <header.Trigger class="faq-trigger">{{q.question}}</header.Trigger>
        </item.Header>
        <item.Content class="faq-content">{{q.answer}}</item.Content>
      </accordion.Item>
    {{/each}}
  </Accordion>
  <style>
    .faq {
      max-width: 24rem;
      font-size: 0.875rem;
    }
    .faq-item {
      border-bottom: 1px solid;
    }
    .faq-header {
      margin: 0;
      font: inherit;
    }
    .faq-trigger {
      width: 100%;
      padding: 0.75rem 0;
      border: 0;
      background: none;
      color: inherit;
      font: inherit;
      font-weight: 600;
      text-align: start;
    }
    .faq-trigger[aria-expanded="true"] {
      text-decoration: underline;
    }
    .faq-content {
      padding-bottom: 0.75rem;
    }
  </style>
</template>
