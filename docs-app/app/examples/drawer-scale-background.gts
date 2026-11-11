import { Button, Drawer } from '@ember-joinery/ember'

<template>
  {{! The page behind: in an app, its root element carries data-vaul-drawer-wrapper. }}
  <div
    class="flex w-full max-w-md flex-col items-center gap-4 rounded-xl border bg-background p-8"
    data-vaul-drawer-wrapper
  >
    <p class="text-center text-sm text-muted-foreground">
      This box is the page. While the drawer is open, it scales back behind it.
    </p>
    <Drawer @shouldScaleBackground={{true}} @setBackgroundColorOnScale={{false}} as |d|>
      <Button @variant="outline" {{d.trigger}}>Open Drawer</Button>
      <d.Content>
        <div class="mx-auto w-full max-w-sm">
          <d.Header>
            <d.Title>Scaled background</d.Title>
            <d.Description>Drag this down, and the page comes forward with it.</d.Description>
          </d.Header>
          <d.Footer>
            <Button @variant="outline" {{d.close}}>Close</Button>
          </d.Footer>
        </div>
      </d.Content>
    </Drawer>
  </div>
</template>
