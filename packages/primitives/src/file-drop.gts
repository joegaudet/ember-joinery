import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type Owner from '@ember/owner'
import { idFor } from './id.ts'
import { visuallyHidden } from './visually-hidden.gts'

/**
 * One entry of an `accept` list: an extension (`.mp4`), a type with a wildcard (`video/*`), or
 * an exact type (`video/webm`).
 */
function acceptsOne(file: File, entry: string): boolean {
  if (entry.startsWith('.')) return file.name.toLowerCase().endsWith(entry.toLowerCase())
  if (entry.endsWith('/*')) return file.type.startsWith(entry.slice(0, -1))
  return file.type === entry
}

/**
 * Whether a file matches an `accept` list, as `<input type="file">` reads it. The file picker
 * filters by `accept` itself, but a drop doesn't, so dropped files need this check.
 */
export function accepts(file: File, accept: string | undefined): boolean {
  if (!accept) return true
  return accept.split(',').some(entry => {
    const trimmed = entry.trim()
    return Boolean(trimmed) && acceptsOne(file, trimmed)
  })
}

/**
 * Whether a drag carries files. A drag can carry text or a link instead, and during the drag
 * only the types are readable, not the files.
 */
export function hasFiles(event: DragEvent): boolean {
  const types = event.dataTransfer?.types
  if (!types) return false
  return [...types].includes('Files')
}

/**
 * The files of a pick or a drop that match `accept`, and only the first of them unless
 * `multiple` is set.
 */
export function filesFrom(
  list: FileList | null | undefined,
  accept: string | undefined,
  multiple: boolean | undefined,
): File[] {
  const files: File[] = []
  if (!list) return files
  for (const file of list) {
    if (!accepts(file, accept)) continue
    files.push(file)
    if (!multiple) break
  }
  return files
}

/**
 * Whether files are dragged over an element. `dragenter` and `dragleave` fire for every child
 * the pointer crosses, so a single flag would flicker; the depth counts the enters that haven't
 * left yet.
 */
export class DragState {
  @tracked isDragging = false
  #depth = 0

  enter(event: DragEvent): void {
    if (!hasFiles(event)) return
    this.#depth++
    this.isDragging = true
  }

  leave(event: DragEvent): void {
    if (!hasFiles(event)) return
    this.#depth = Math.max(0, this.#depth - 1)
    if (this.#depth === 0) this.isDragging = false
  }

  end(): void {
    this.#depth = 0
    this.isDragging = false
  }
}

/** What both `<FileDrop>` and `<DocumentFileDrop>` take. */
export interface FileDropArgs {
  /** Called with the files that match `@accept`. It isn't called when no file matches. */
  onFiles: (files: File[]) => void
  /**
   * Which files to take, as `<input type="file">`'s `accept` reads it, such as
   * `"video/*,.mkv"`. The file picker shows only these, and a drop of others does nothing.
   */
  accept?: string
  /** Whether to take more than one file. Without it, only the first that matches. */
  multiple?: boolean
}

export interface FileDropSignature {
  Args: FileDropArgs & {
    /** Whether it takes no files: its input is disabled, and drops are ignored. */
    disabled?: boolean
    /** Its name, for `FileDropHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [
      zone: {
        /** Whether files are dragged over it. */
        isDragging: boolean
      },
    ]
  }
  /**
   * A `<label>` for a visually hidden `<input type="file">`, so a press on the zone, or Enter
   * or Space on its input, opens the file picker. It has `data-dragging` while files are
   * dragged over it.
   */
  Element: HTMLLabelElement
}

/**
 * A zone to drop files on, or to press to pick them: ember-primitives' FileDrop, headless.
 *
 *   <FileDrop @accept="video/*" @onFiles={{this.load}} as |zone|>
 *     {{if zone.isDragging "Let go to add it" "Drop a video here, or click to choose one"}}
 *   </FileDrop>
 *
 * Its text names its input, which stays in the tab order; show the zone's focus with
 * `:focus-within`, because the focused input is hidden.
 */
export class FileDrop extends Component<FileDropSignature> {
  drag = new DragState()

  get inputId(): string {
    return idFor(this, 'input')
  }

  onDragEnter = (event: DragEvent): void => {
    if (!this.args.disabled) this.drag.enter(event)
  }

  onDragLeave = (event: DragEvent): void => this.drag.leave(event)

  /** Without this, the browser doesn't allow the drop. */
  onDragOver = (event: DragEvent): void => {
    if (hasFiles(event) && !this.args.disabled) event.preventDefault()
  }

  /** `preventDefault()` also tells a `DocumentFileDrop` that this zone took the drop. */
  onDrop = (event: DragEvent): void => {
    this.drag.end()
    if (!hasFiles(event)) return
    event.preventDefault()
    if (this.args.disabled) return
    this.take(event.dataTransfer?.files)
  }

  /** The input is cleared after each pick, so that picking the same file again is a change too. */
  onPick = (event: Event): void => {
    const input = event.currentTarget as HTMLInputElement
    this.take(input.files)
    input.value = ''
  }

  take(list: FileList | null | undefined): void {
    const files = filesFrom(list, this.args.accept, this.args.multiple)
    if (files.length > 0) this.args.onFiles(files)
  }

  <template>
    <label
      for={{this.inputId}}
      data-dragging={{if this.drag.isDragging ""}}
      data-disabled={{if @disabled ""}}
      data-test-jn="file-drop"
      data-test-jn-name={{@name}}
      ...attributes
      {{on "dragenter" this.onDragEnter}}
      {{on "dragover" this.onDragOver}}
      {{on "dragleave" this.onDragLeave}}
      {{on "drop" this.onDrop}}
    >
      {{yield (hash isDragging=this.drag.isDragging)}}
      <input
        id={{this.inputId}}
        type="file"
        accept={{@accept}}
        multiple={{@multiple}}
        disabled={{@disabled}}
        data-test-jn-part="input"
        {{visuallyHidden}}
        {{on "change" this.onPick}}
      />
    </label>
  </template>
}

export interface DocumentFileDropSignature {
  Args: FileDropArgs
  Blocks: {
    default: [
      page: {
        /** Whether files are dragged over the page. */
        isDragging: boolean
      },
    ]
  }
}

/**
 * Takes files dropped anywhere on the page: ember-primitives' DocumentFileDrop. It renders no
 * element of its own, only its block.
 *
 * - The block gets `isDragging`, to show where a drop goes.
 * - A drop outside every `FileDrop` doesn't open the file in the browser tab.
 * - A drop on a `FileDrop` goes only to that `FileDrop`.
 *
 *   <DocumentFileDrop @accept="video/*" @onFiles={{this.load}} as |page|>
 *     {{#if page.isDragging}}<div class="overlay">Drop to load</div>{{/if}}
 *   </DocumentFileDrop>
 */
export class DocumentFileDrop extends Component<DocumentFileDropSignature> {
  drag = new DragState()

  constructor(owner: Owner, args: DocumentFileDropSignature['Args']) {
    super(owner, args)
    document.addEventListener('dragenter', this.onDragEnter)
    document.addEventListener('dragover', this.onDragOver)
    document.addEventListener('dragleave', this.onDragLeave)
    document.addEventListener('drop', this.onDrop)
    registerDestructor(this, () => {
      document.removeEventListener('dragenter', this.onDragEnter)
      document.removeEventListener('dragover', this.onDragOver)
      document.removeEventListener('dragleave', this.onDragLeave)
      document.removeEventListener('drop', this.onDrop)
    })
  }

  onDragEnter = (event: DragEvent): void => this.drag.enter(event)
  onDragLeave = (event: DragEvent): void => this.drag.leave(event)

  onDragOver = (event: DragEvent): void => {
    if (hasFiles(event)) event.preventDefault()
  }

  onDrop = (event: DragEvent): void => {
    this.drag.end()
    if (!hasFiles(event) || event.defaultPrevented) return
    event.preventDefault()
    const files = filesFrom(event.dataTransfer?.files, this.args.accept, this.args.multiple)
    if (files.length > 0) this.args.onFiles(files)
  }

  <template>{{yield (hash isDragging=this.drag.isDragging)}}</template>
}

export default FileDrop
