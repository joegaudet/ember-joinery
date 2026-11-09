import { Button, Dialog } from '@ember-joinery/ember'

const PARAGRAPHS = Array.from({ length: 10 }, (_, index) => index)

<template>
  <Dialog as |d|>
    <Button @variant="outline" {{d.trigger}}>Scrollable Content</Button>
    <d.Content>
      <d.Header>
        <d.Title>Scrollable Content</d.Title>
        <d.Description>
          This is a dialog with scrollable content.
        </d.Description>
      </d.Header>
      {{! Upstream's scrolling region takes no focus, so a keyboard can't scroll it;
          this one can (tabindex="0"), which the accessibility audit asks for. }}
      <div class="-mx-4 no-scrollbar max-h-[50vh] overflow-y-auto px-4" tabindex="0">
        {{#each PARAGRAPHS}}
          <p class="mb-4 leading-normal">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
            incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
            exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure
            dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
            Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt
            mollit anim id est laborum.
          </p>
        {{/each}}
      </div>
    </d.Content>
  </Dialog>
</template>
