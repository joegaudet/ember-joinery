import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Resizable } from '@ember-joinery/primitives/resizable'

/**
 * A headless layout: a collapsible file list beside an editor, styled with nothing but
 * utilities. The layout it saves (what an app would keep in localStorage) is the layout it
 * opens with.
 */
export default class ResizableHeadless extends Component {
  @tracked saved: readonly number[] = [30, 70]

  save = (sizes: number[]) => (this.saved = sizes)

  get summary(): string {
    return this.saved.map(size => `${Math.round(size)}%`).join(' · ')
  }

  <template>
    <div class="flex w-full max-w-md flex-col gap-2">
      <Resizable
        @defaultLayout={{this.saved}}
        @onLayoutChanged={{this.save}}
        class="h-48 w-full rounded-md border"
        as |r|
      >
        <r.Panel @id="files" @minSize="20%" @collapsible={{true}} as |panel|>
          <div class="flex h-full flex-col items-start gap-2 p-3 text-sm">
            <span class="font-semibold">Files</span>
            <button type="button" class="underline" {{on "click" panel.collapse}}>Hide</button>
          </div>
        </r.Panel>
        <r.Handle
          aria-label="Resize the files"
          class="w-1 bg-border outline-ring focus-visible:outline-2"
        />
        <r.Panel @id="editor">
          <div class="p-3 text-sm">Editor</div>
        </r.Panel>
      </Resizable>
      <p class="text-xs text-muted-foreground">Saved: <output>{{this.summary}}</output></p>
    </div>
  </template>
}
