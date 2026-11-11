import { Button, Sheet, type SheetSide } from '@ember-joinery/ember'

const SHEET_SIDES: SheetSide[] = ['top', 'right', 'bottom', 'left']
const PARAGRAPHS = Array.from({ length: 10 }, (_, index) => index)

<template>
  <div class="flex flex-wrap gap-2">
    {{#each SHEET_SIDES as |side|}}
      <Sheet as |s|>
        <Button @variant="outline" class="capitalize" {{s.trigger}}>
          {{side}}
        </Button>
        <s.Content
          @side={{side}}
          class="data-[side=bottom]:max-h-[50vh] data-[side=top]:max-h-[50vh]"
        >
          <s.Header>
            <s.Title>Edit profile</s.Title>
            <s.Description>
              Make changes to your profile here. Click save when you're done.
            </s.Description>
          </s.Header>
          {{! Upstream's scrolling region takes no focus, so a keyboard can't scroll it;
              this one can (tabindex="0"), which the accessibility audit asks for. }}
          <div class="no-scrollbar overflow-y-auto px-4" tabindex="0">
            {{#each PARAGRAPHS}}
              <p class="mb-2 leading-relaxed">
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
                incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
                exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute
                irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
                pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia
                deserunt mollit anim id est laborum.
              </p>
            {{/each}}
          </div>
          <s.Footer>
            <Button type="submit">Save changes</Button>
            <Button @variant="outline" {{s.close}}>Cancel</Button>
          </s.Footer>
        </s.Content>
      </Sheet>
    {{/each}}
  </div>
</template>
