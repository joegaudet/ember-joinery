import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { FileDrop } from '@ember-joinery/primitives/file-drop'

export default class FileDropHeadless extends Component {
  @tracked picked = 'nothing yet'

  show = (files: File[]) => (this.picked = files.map(file => file.name).join(', '))

  <template>
    {{!
      The headless drop zone, as ember-primitives' demo styles it: a label for a hidden file
      input, with data-dragging while files are over it. Show its focus with focus-within.
    }}
    <div class="flex w-full max-w-sm flex-col gap-3">
      <FileDrop
        class="block cursor-pointer rounded-lg border-2 border-dashed p-8 text-center text-sm focus-within:outline-2 focus-within:outline-offset-2 data-dragging:border-solid"
        @accept="image/*"
        @multiple={{true}}
        @onFiles={{this.show}}
        as |zone|
      >
        {{if zone.isDragging "Let go to add the images" "Drop images here, or click to choose"}}
      </FileDrop>
      <p class="text-sm">Picked: {{this.picked}}</p>
    </div>
  </template>
}
