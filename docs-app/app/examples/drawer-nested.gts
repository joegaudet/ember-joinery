import { Button, Drawer } from '@ember-joinery/ember'

<template>
  <Drawer as |d|>
    <Button @variant="outline" {{d.trigger}}>Open Drawer</Button>
    <d.Content>
      <div class="mx-auto w-full max-w-sm">
        <d.Header>
          <d.Title>Nested drawers</d.Title>
          <d.Description>
            A drawer opened from this one steps it back, and lets it forward again as it goes.
          </d.Description>
        </d.Header>
        <d.Footer>
          <d.Nested as |n|>
            <Button {{n.trigger}}>Open the second drawer</Button>
            <n.Content>
              <div class="mx-auto w-full max-w-sm">
                <n.Header>
                  <n.Title>The second drawer</n.Title>
                  <n.Description>Drag it down, or press Escape, to go back.</n.Description>
                </n.Header>
                <n.Footer>
                  <Button @variant="outline" {{n.close}}>Back</Button>
                </n.Footer>
              </div>
            </n.Content>
          </d.Nested>
          <Button @variant="outline" {{d.close}}>Close</Button>
        </d.Footer>
      </div>
    </d.Content>
  </Drawer>
</template>
