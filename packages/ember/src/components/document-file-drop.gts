import type { TOC } from '@ember/component/template-only'
import { DocumentFileDrop as DocumentFileDropPrimitive } from '@ember-joinery/primitives/file-drop'

export interface DocumentFileDropSignature {
  Args: {
    /** Called with the files dropped anywhere on the page that match `@accept`. */
    onFiles: (files: File[]) => void
    /** Which files to take, as `<input type="file">`'s `accept` reads it. */
    accept?: string
    /** Whether to take more than one file. Without it, only the first that matches. */
    multiple?: boolean
    /** What the overlay says, without a block. Default `Drop files anywhere`. */
    label?: string
    /** Its name, for `DocumentFileDropHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** What the overlay shows while files are dragged over the page. Default: `@label`. */
    default: []
  }
  Element: HTMLDivElement
}

/**
 * Takes files dropped anywhere on the page, and covers the page with an overlay while they are
 * dragged over it: ember-primitives' DocumentFileDrop, drawn in shadcn's terms. The overlay
 * lets the pointer through, so a `FileDrop` under it still takes a drop on itself, and a drop
 * elsewhere doesn't open the file in the browser tab.
 *
 *   <DocumentFileDrop @accept="image/*" @onFiles={{this.add}} />
 */
const DocumentFileDrop: TOC<DocumentFileDropSignature> = <template>
  <DocumentFileDropPrimitive
    @onFiles={{@onFiles}}
    @accept={{@accept}}
    @multiple={{@multiple}}
    as |page|
  >
    {{#if page.isDragging}}
      <div
        class="jn-document-file-drop"
        data-slot="document-file-drop"
        data-test-jn="document-file-drop"
        data-test-jn-name={{@name}}
        ...attributes
      >
        <div class="jn-document-file-drop-content" data-slot="document-file-drop-content">
          {{#if (has-block)}}{{yield}}{{else}}{{if @label @label "Drop files anywhere"}}{{/if}}
        </div>
      </div>
    {{/if}}
  </DocumentFileDropPrimitive>
</template>

export default DocumentFileDrop
