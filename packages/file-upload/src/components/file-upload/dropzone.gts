import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import FileDropzone from 'ember-file-upload/components/file-dropzone'
import type { UploadFile } from 'ember-file-upload'
import { Upload as UploadIcon } from 'lucide'
import Icon from '@ember-joinery/ember/components/icon'
import type { FileUploadContext } from './context.ts'

/** What a drop zone's block gets: whether files are dragged over it, and whether it can tell. */
export interface FileUploadDropzoneState {
  /** Whether files are dragged over the zone now. */
  isDragging: boolean
  /** Whether the browser can drag and drop files (every evergreen browser can). */
  isSupported: boolean
}

export interface FileUploadDropzoneSignature {
  Args: {
    /** The `<FileUpload>` it belongs to; `u.Dropzone` comes with it. */
    upload: FileUploadContext
  }
  Blocks: {
    /**
     * What the zone shows, in place of its icon, prompt and hint. It names the zone's file
     * input, so say what a press on it does.
     */
    default: [zone: FileUploadDropzoneState]
  }
  /** ember-file-upload's `FileDropzone`: a `<div>`. */
  Element: HTMLElement
}

/**
 * The zone to drop files on, or to press to choose them: ember-file-upload's `FileDropzone`
 * around a visually hidden `<input type="file">`, in the look of shadcn's Empty with a dashed
 * border. It turns `--primary` while files are dragged over it, shows the focus ring while its
 * input has focus, and names the files a drop turned away under its prompt.
 */
export default class FileUploadDropzone extends Component<FileUploadDropzoneSignature> {
  @tracked isDragging = false

  get state() {
    return this.args.upload.state
  }

  get labels() {
    return this.args.upload.labels
  }

  get rejected(): string | undefined {
    const names = this.state.rejected
    return names.length ? this.labels.rejectedLabel([...names]) : undefined
  }

  /** Whether to say files can be dropped: only where they can be, and while it takes them. */
  get showsHint(): boolean {
    return !this.state.disabled
  }

  get description(): string | undefined {
    return this.labels.description ?? this.state.accept
  }

  enter = (): void => {
    if (!this.state.disabled) this.isDragging = true
  }

  leave = (): void => {
    this.isDragging = false
  }

  drop = (files: UploadFile[], transfer: { files: File[] }): void => {
    this.isDragging = false
    this.state.onDrop(files, transfer)
  }

  <template>
    <FileDropzone
      @queue={{this.state.queue}}
      @multiple={{this.state.multiple}}
      @filter={{this.state.filter}}
      @onDragEnter={{this.enter}}
      @onDragLeave={{this.leave}}
      @onDrop={{this.drop}}
      class="jn-file-upload-dropzone"
      data-slot="file-upload-dropzone"
      data-dragging={{if this.isDragging ""}}
      data-disabled={{if this.state.disabled ""}}
      data-invalid={{if @upload.invalid ""}}
      data-test-jn-part="dropzone"
      ...attributes
      as |dropzone|
    >
      <label class="jn-file-upload-dropzone-label" data-slot="file-upload-dropzone-label">
        <input
          id={{@upload.inputId}}
          class="jn-file-upload-input"
          type="file"
          accept={{this.state.accept}}
          multiple={{this.state.multiple}}
          disabled={{this.state.disabled}}
          required={{@upload.required}}
          aria-label={{@upload.label}}
          aria-invalid={{if @upload.invalid "true"}}
          aria-describedby={{@upload.describedBy}}
          data-test-jn-part="input"
          {{this.state.queue.selectFile
            filter=this.state.filter
            onFilesSelected=this.state.onSelect
          }}
        />
        {{#if (has-block)}}
          {{yield (hash isDragging=this.isDragging isSupported=dropzone.supported)}}
        {{else}}
          <span class="jn-empty-header" data-slot="file-upload-dropzone-header">
            <span class="jn-empty-media jn-empty-media-icon" data-slot="file-upload-dropzone-media">
              <Icon @icon={{UploadIcon}} />
            </span>
            <span class="jn-empty-title jn-font-heading" data-slot="file-upload-dropzone-title">
              {{if this.isDragging this.labels.dropLabel this.labels.prompt}}
            </span>
            {{#if dropzone.supported}}
              {{#if this.showsHint}}
                {{#unless this.isDragging}}
                  <span class="jn-empty-description" data-slot="file-upload-dropzone-hint">
                    {{this.labels.hint}}
                  </span>
                {{/unless}}
              {{/if}}
            {{/if}}
            {{#if this.description}}
              <span class="jn-empty-description" data-slot="file-upload-dropzone-description">
                {{this.description}}
              </span>
            {{/if}}
          </span>
        {{/if}}
      </label>
      {{#if this.rejected}}
        <p
          class="jn-file-upload-rejected"
          data-slot="file-upload-rejected"
          role="status"
          data-test-jn-part="rejected"
        >{{this.rejected}}</p>
      {{/if}}
    </FileDropzone>
  </template>
}
