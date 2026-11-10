import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type Owner from '@ember/owner'
import type { WithBoundArgs } from '@glint/template'
import type { Queue } from 'ember-file-upload'
import { modifier } from 'ember-modifier'
import FileUploadDropzone from './dropzone.gts'
import FileUploadList from './list.gts'
import FileUploadQueue from './queue.gts'
import {
  defaultProgressLabel,
  defaultRejectedLabel,
  defaultRemoveLabel,
  defaultRetryLabel,
  type FileUploadLabels,
} from './labels.ts'
import {
  FileUploadState,
  type FileEntry,
  type FileState,
  type FocusRequest,
  type Upload,
  type UploadFn,
} from './state.ts'
import type { FileUploadContext } from './context.ts'

export type { FileEntry, FileState, FileUploadLabels, Upload, UploadFn }
export type { FileUploadDropzoneSignature, FileUploadDropzoneState } from './dropzone.gts'
export type { FileUploadListSignature } from './list.gts'
export type { FileUploadQueueSignature } from './queue.gts'

/** What `<FileUpload>` yields: its parts, its files and uploads, and what it can do with them. */
export interface FileUploadYield<T> {
  /** The zone to drop files on, or to press to choose them. */
  Dropzone: WithBoundArgs<typeof FileUploadDropzone, 'upload'>
  /** The files the value holds, one Item each, with a remove button. */
  List: WithBoundArgs<typeof FileUploadList, 'upload'>
  /** The files uploading or failed, one Item each, with a Progress bar. */
  Queue: WithBoundArgs<typeof FileUploadQueue, 'upload'>
  /** The files the value holds, as the list shows them. */
  files: FileEntry<T>[]
  /** The uploads in the queue: each has `name`, `progress`, `state` and `error`. */
  uploads: readonly Upload[]
  /** Whether any upload is running. */
  isUploading: boolean
  /** Takes a value out of the list. */
  remove: (value: T) => void
  /** Empties the list. */
  clear: () => void
  /** Uploads a failed file again. */
  retry: (upload: Upload) => void
  /** ember-file-upload's queue the chosen files go into. */
  queue: Queue
}

export interface FileUploadSignature<T = File> {
  Args: {
    /** Whether it takes more than one file. Without it, a new choice replaces the file. */
    multiple?: boolean
    /** Which files to take, as `<input accept>` reads it: `.pdf`, `image/*`, `text/csv`… */
    accept?: string
    /** Whether it takes no files and removes none. */
    disabled?: boolean
    /** The files (or, with `@upload`, what each upload resolved to), when the caller controls them. */
    value?: readonly T[]
    /** The files it starts with, uncontrolled. */
    defaultValue?: readonly T[]
    /** Called with the new list whenever a file is added or removed. */
    onValueChange?: (value: T[]) => void
    /**
     * Uploads each chosen file as it is chosen, and resolves with what the value keeps for it.
     * Until it settles, the file is in the upload queue. Without it, the value keeps each `File`.
     */
    upload?: UploadFn<T>
    /** An ember-file-upload queue to put the files in, such as one of its `file-queue` service's. */
    queue?: Queue
    /** A value's name in the list. Default: a file's name, or a record's `name` or `label`. */
    nameOf?: (value: T) => string
    /** A value's size in bytes. Default: its `size`. */
    sizeOf?: (value: T) => number | undefined
    /** A URL of an image of a value. Default: an image file's own contents. */
    previewOf?: (value: T) => string | undefined
    /** The locale sizes are written in (`Intl`). Default: the browser's. */
    locale?: string
    /** The file input's `id`, so a `<label for>` (a FieldLabel) names it. */
    id?: string
    /** The file input's `aria-label`, in place of the zone's text. */
    label?: string
    /** Whether a file is required. */
    required?: boolean
    /** Whether the value is invalid: `aria-invalid` on the input, and a destructive border. */
    invalid?: boolean
    /** The ids of what describes the input (`aria-describedby`), such as a FieldDescription. */
    describedBy?: string
    /** The zone's call to action. Default `Choose a file`, or `Choose files` with `@multiple`. */
    prompt?: string
    /** What follows it. Default `or drag and drop here`. */
    hint?: string
    /** What the zone says while files are dragged over it. Default `Drop to add`. */
    dropLabel?: string
    /** A line under the hint, such as `PDF, up to 5 MB`. Default: `@accept`. */
    description?: string
    /** Names the files a drop turned away. Default `Not an accepted type: a.exe, b.exe`. */
    rejectedLabel?: (names: string[]) => string
    /** Names a file's remove button. Default `Remove cv.pdf`. */
    removeLabel?: (name: string) => string
    /** Names a failed upload's retry button. Default `Retry cv.pdf`. */
    retryLabel?: (name: string) => string
    /** Names a file's progress bar while it uploads. Default `Uploading cv.pdf`. */
    progressLabel?: (name: string) => string
    /** The error an upload shows when it fails without a message. Default `Upload failed`. */
    uploadFailedLabel?: string
    /** Its name, for `FileUploadHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** Its parts, laid out as you like. Without a block: the zone, the list, then the queue. */
    default: [FileUploadYield<T>]
  }
  Element: HTMLDivElement
}

const handled = new WeakSet<FocusRequest>()

/**
 * Once a removal has rendered, moves focus from the button that went to the one in the row that
 * took its place (or the row before it), or to the file input when its list emptied. It moves
 * focus only when it was lost with the button, so it never takes focus from somewhere else.
 */
const focusAfterRemoval = modifier(
  (element: HTMLElement, [request]: [FocusRequest | undefined]) => {
    if (!request || handled.has(request)) return
    handled.add(request)
    const active = element.ownerDocument.activeElement
    if (active && active !== element.ownerDocument.body && active.isConnected) return
    const list = element.querySelector(`.jn-file-upload-${request.list}`)
    const rows = list ? [...list.querySelectorAll(':scope > .jn-file-upload-file')] : []
    const row = rows[request.index] ?? rows[request.index - 1]
    const target =
      row?.querySelector<HTMLElement>('.jn-file-upload-remove') ??
      element.querySelector<HTMLElement>('.jn-file-upload-remove') ??
      element.querySelector<HTMLElement>('.jn-file-upload-input')
    target?.focus()
  },
)

/**
 * File uploads in shadcn's look, on ember-file-upload: a drop zone around a native file input, the
 * list of chosen files (an Item each, with a preview, the name and size, and a remove button), and,
 * with `@upload`, a queue of the files uploading, each with a Progress bar.
 *
 *   <FileUpload @multiple={{true}} @accept="image/*,.pdf" @onValueChange={{this.setFiles}} />
 *
 *   <FileUpload @upload={{this.upload}} as |u|>
 *     <u.Dropzone />
 *     <u.List />
 *     <u.Queue />
 *   </FileUpload>
 *
 * The value is always a list: of `File`s, or, with `@upload`, of what each upload resolved to.
 * Without `@multiple` it holds one at most, and a new choice replaces it.
 */
export default class FileUpload<T = File> extends Component<FileUploadSignature<T>> {
  readonly state: FileUploadState<T>

  constructor(owner: Owner, args: FileUploadSignature<T>['Args']) {
    super(owner, args)
    this.state = new FileUploadState<T>(this, {
      multiple: () => this.args.multiple,
      accept: () => this.args.accept,
      disabled: () => this.args.disabled,
      value: () => this.args.value,
      defaultValue: () => this.args.defaultValue,
      onValueChange: () => this.args.onValueChange,
      upload: () => this.args.upload,
      queue: () => this.args.queue,
      nameOf: () => this.args.nameOf,
      sizeOf: () => this.args.sizeOf,
      previewOf: () => this.args.previewOf,
      uploadFailedLabel: () => this.args.uploadFailedLabel,
      locale: () => this.args.locale,
    })
  }

  get labels(): FileUploadLabels {
    const multiple = this.state.multiple
    return {
      prompt: this.args.prompt ?? (multiple ? 'Choose files' : 'Choose a file'),
      hint: this.args.hint ?? 'or drag and drop here',
      dropLabel: this.args.dropLabel ?? 'Drop to add',
      description: this.args.description,
      rejectedLabel: this.args.rejectedLabel ?? defaultRejectedLabel,
      removeLabel: this.args.removeLabel ?? defaultRemoveLabel,
      retryLabel: this.args.retryLabel ?? defaultRetryLabel,
      progressLabel: this.args.progressLabel ?? defaultProgressLabel,
    }
  }

  /** What the parts read: the state, the strings, and the input's arguments. */
  get context(): FileUploadContext {
    const { state } = this
    return {
      state,
      labels: this.labels,
      inputId: this.args.id,
      label: this.args.label,
      invalid: this.args.invalid,
      describedBy: this.args.describedBy,
      required: this.args.required,
    }
  }

  <template>
    {{#let
      (hash
        Dropzone=(component FileUploadDropzone upload=this.context)
        List=(component FileUploadList upload=this.context)
        Queue=(component FileUploadQueue upload=this.context)
        files=this.state.files
        uploads=this.state.uploads
        isUploading=this.state.isUploading
        remove=this.state.remove
        clear=this.state.clear
        retry=this.state.retry
        queue=this.state.queue
      )
      as |u|
    }}
      <div
        class="jn-file-upload"
        data-slot="file-upload"
        data-multiple={{if this.state.multiple ""}}
        data-disabled={{if this.state.disabled ""}}
        data-uploading={{if this.state.isUploading ""}}
        aria-busy={{if this.state.isUploading "true"}}
        data-test-jn="file-upload"
        data-test-jn-name={{@name}}
        {{focusAfterRemoval this.state.focusRequest}}
        ...attributes
      >
        {{#if (has-block)}}
          {{yield u}}
        {{else}}
          <u.Dropzone />
          <u.List />
          <u.Queue />
        {{/if}}
      </div>
    {{/let}}
  </template>
}
