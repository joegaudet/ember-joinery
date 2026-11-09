import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Upload } from 'lucide'
import { FileDrop, Icon } from '@ember-joinery/ember'

export default class FileDropDemo extends Component {
  @tracked names: string[] = []

  add = (files: File[]) => (this.names = files.map(file => file.name))

  get picked(): string {
    return this.names.join(', ')
  }

  <template>
    {{! Joinery's own: shadcn/ui has no drop zone. }}
    <div class="flex w-full max-w-sm flex-col gap-3">
      <FileDrop @accept="image/*" @multiple={{true}} @onFiles={{this.add}} as |zone|>
        <Icon @icon={{Upload}} />
        {{if zone.isDragging "Drop to upload" "Drag images here, or click to choose"}}
      </FileDrop>
      <p class="text-sm text-muted-foreground">
        {{#if this.names.length}}Picked: {{this.picked}}{{else}}Nothing picked yet.{{/if}}
      </p>
    </div>
  </template>
}
