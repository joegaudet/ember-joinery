import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. The first panel is on the right, and the arrow keys and the pointer follow: Left
    moves a handle left.
  }}
  <ResizablePanelGroup @orientation="horizontal" class="max-w-sm rounded-lg border">
    <ResizablePanel @defaultSize="50%">
      <div class="flex h-[200px] items-center justify-center p-6">
        <span class="font-semibold">واحد</span>
      </div>
    </ResizablePanel>
    <ResizableHandle @withHandle={{true}} />
    <ResizablePanel @defaultSize="50%">
      <ResizablePanelGroup @orientation="vertical">
        <ResizablePanel @defaultSize="25%">
          <div class="flex h-full items-center justify-center p-6">
            <span class="font-semibold">اثنان</span>
          </div>
        </ResizablePanel>
        <ResizableHandle @withHandle={{true}} />
        <ResizablePanel @defaultSize="75%">
          <div class="flex h-full items-center justify-center p-6">
            <span class="font-semibold">ثلاثة</span>
          </div>
        </ResizablePanel>
      </ResizablePanelGroup>
    </ResizablePanel>
  </ResizablePanelGroup>
</template>
