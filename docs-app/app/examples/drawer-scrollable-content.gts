import { Button, Drawer } from '@ember-joinery/ember'

const PARAGRAPHS = Array.from({ length: 10 }, (_, index) => index)

<template>
  <Drawer @direction="right" as |d|>
    <Button @variant="outline" {{d.trigger}}>Scrollable Content</Button>
    <d.Content>
      <d.Header>
        <d.Title>Move Goal</d.Title>
        <d.Description>Set your daily activity goal.</d.Description>
      </d.Header>
      {{! Upstream's scrolling region takes no focus, so a keyboard can't scroll it;
          this one can (tabindex="0"), which the accessibility audit asks for. }}
      <div class="no-scrollbar overflow-y-auto px-4" tabindex="0">
        {{#each PARAGRAPHS}}
          <p class="mb-4 leading-normal style-lyra:mb-2 style-lyra:leading-relaxed">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
            incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
            exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure
            dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
            Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt
            mollit anim id est laborum.
          </p>
        {{/each}}
      </div>
      <d.Footer>
        <Button>Submit</Button>
        <Button @variant="outline" {{d.close}}>Cancel</Button>
      </d.Footer>
    </d.Content>
  </Drawer>
</template>
