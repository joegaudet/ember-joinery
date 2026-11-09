import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { DocumentFileDrop } from '@ember-joinery/primitives/file-drop'

export default class FileDropDocumentHeadless extends Component {
  @tracked dropped = 'nothing yet'

  show = (files: File[]) => (this.dropped = files[0]!.name)

  <template>
    {{!
      ember-primitives' "Drop anywhere on the page" demo, styled with utility classes: the
      block's own element shows the drag with data-dragging, while page.isDragging is true.
    }}
    <DocumentFileDrop @onFiles={{this.show}} as |page|>
      <p
        class="rounded-lg border-2 border-dashed border-transparent p-4 text-sm data-dragging:border-current data-dragging:bg-current/10"
        data-dragging={{page.isDragging}}
        data-test-jn="page-drop"
      >
        {{if page.isDragging "Drop the file anywhere on the page" "Dropped: "}}
        {{unless page.isDragging this.dropped}}
      </p>
    </DocumentFileDrop>
  </template>
}
