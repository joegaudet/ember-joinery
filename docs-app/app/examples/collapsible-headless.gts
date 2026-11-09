import { Collapsible } from '@ember-joinery/primitives/collapsible'

<template>
  <Collapsible class="disclosure" as |c|>
    <c.Trigger class="disclosure-trigger">
      Can I use this in my project?
      <span aria-hidden="true">{{if c.isOpen "−" "+"}}</span>
    </c.Trigger>
    <c.Content class="disclosure-content">
      Yes. Free to use for personal and commercial projects. No attribution required.
    </c.Content>
  </Collapsible>
  <style>
    .disclosure {
      display: grid;
      gap: 0.5rem;
      max-width: 24rem;
      font-size: 0.875rem;
    }
    .disclosure-trigger {
      display: flex;
      justify-content: space-between;
      padding: 0.5rem 0.75rem;
      border: 1px solid;
      border-radius: 0.5rem;
      background: none;
      color: inherit;
      font: inherit;
    }
    .disclosure-content {
      overflow: hidden;
      padding: 0 0.75rem;
    }
    .disclosure-content[data-state="open"] {
      animation: disclosure-open 200ms ease-out;
    }
    .disclosure-content[data-state="closed"] {
      animation: disclosure-close 200ms ease-out;
    }
    @keyframes disclosure-open {
      from {
        height: 0;
      }
      to {
        height: var(--radix-collapsible-content-height);
      }
    }
    @keyframes disclosure-close {
      from {
        height: var(--radix-collapsible-content-height);
      }
      to {
        height: 0;
      }
    }
  </style>
</template>
