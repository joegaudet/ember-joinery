import type { TOC } from '@ember/component/template-only'
import { FileDrop as FileDropPrimitive } from '@ember-joinery/primitives/file-drop'

export interface FileDropSignature {
  Args: {
    /** Called with the files that match `@accept`. It isn't called when no file matches. */
    onFiles: (files: File[]) => void
    /** Which files to take, as `<input type="file">`'s `accept` reads it: `"image/*,.pdf"`. */
    accept?: string
    /** Whether to take more than one file. Without it, only the first that matches. */
    multiple?: boolean
    /** Whether it takes no files. */
    disabled?: boolean
    /** Its name, for `FileDropHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** What the zone shows, which names its file input: an icon and a line of text. */
    default: [zone: { isDragging: boolean }]
  }
  Element: HTMLLabelElement
}

/**
 * A zone to drop files on, or to press to pick them: ember-primitives' FileDrop, drawn in
 * shadcn's terms (shadcn/ui has none of its own). A dashed box in `--input`, which turns
 * `--primary` while files are dragged over it, and shows the focus ring when its hidden input
 * has focus.
 *
 *   <FileDrop @accept="image/*" @multiple={{true}} @onFiles={{this.add}} as |zone|>
 *     {{if zone.isDragging "Drop to upload" "Drag images here, or click to choose"}}
 *   </FileDrop>
 */
const FileDrop: TOC<FileDropSignature> = <template>
  <FileDropPrimitive
    @onFiles={{@onFiles}}
    @accept={{@accept}}
    @multiple={{@multiple}}
    @disabled={{@disabled}}
    @name={{@name}}
    class="jn-file-drop"
    data-slot="file-drop"
    ...attributes
    as |zone|
  >{{yield zone}}</FileDropPrimitive>
</template>

export default FileDrop
