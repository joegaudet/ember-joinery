import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from '@ember-joinery/ember'

<template>
  <ResizablePanelGroup
    @orientation="horizontal"
    class="min-h-[200px] max-w-md rounded-lg border md:min-w-[450px]"
  >
    <ResizablePanel @defaultSize="25%">
      <div class="flex h-full items-center justify-center p-6">
        <span class="font-semibold">Sidebar</span>
      </div>
    </ResizablePanel>
    <ResizableHandle @withHandle={{true}} />
    <ResizablePanel @defaultSize="75%">
      <div class="flex h-full items-center justify-center p-6">
        <span class="font-semibold">Content</span>
      </div>
    </ResizablePanel>
  </ResizablePanelGroup>
</template>
