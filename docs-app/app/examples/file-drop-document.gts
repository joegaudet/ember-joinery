import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Upload } from 'lucide'
import { DocumentFileDrop, Icon } from '@ember-joinery/ember'

export default class FileDropDocument extends Component {
  @tracked dropped = 'nothing yet'

  take = (files: File[]) => (this.dropped = files[0]!.name)

  <template>
    {{!
      Joinery's own: drag a file over any part of the page, and drop it anywhere. The overlay
      shows while it is dragged.
    }}
    <DocumentFileDrop @onFiles={{this.take}}>
      <Icon @icon={{Upload}} />
      Drop the file anywhere on the page
    </DocumentFileDrop>
    <p class="text-sm">Dropped: {{this.dropped}}</p>
  </template>
}
