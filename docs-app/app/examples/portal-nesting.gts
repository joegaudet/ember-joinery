import { Portal } from '@ember-joinery/primitives/portal'

<template>
  <div class="style-wrapper">
    <div data-portal-target></div>

    <button type="button">main content</button>

    <Portal @to="[data-portal-target]">
      <div class="popover">
        <div data-portal-target></div>
        first layer

        <Portal @to="[data-portal-target]">
          <div class="popover">
            <div data-portal-target></div>
            second layer

            <Portal @to="[data-portal-target]">
              <div class="popover">
                tooltip / third layer
              </div>
            </Portal>
          </div>
        </Portal>

      </div>
    </Portal>
  </div>

  <style>
    .style-wrapper .popover {
      position: absolute;
      width: max-content;
      border: 1px solid;
      padding: 1rem;
      color: black;
      margin: 1.25rem;
      background: #fefefe;
      filter: invert(1) drop-shadow(0 0 0.75rem rgba(0, 0, 0, 0.2));
      border-radius: 4px;
    }
    .style-wrapper .button {
      padding: 0.5rem 1rem;
    }
    .style-wrapper {
      height: 100px;
      position: relative;
    }
  </style>
</template>
