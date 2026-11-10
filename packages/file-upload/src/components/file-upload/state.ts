import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { Queue, type UploadFile } from 'ember-file-upload'
import type FileQueueService from 'ember-file-upload/services/file-queue'
import { ControllableState } from '@ember-joinery/primitives/controllable-state'
import { acceptsFile, fileKind, formatFileSize } from '../../utils.ts'

/**
 * Uploads a file the user chose, and resolves with what the value keeps for it: an id, a URL,
 * a record. `file` is ember-file-upload's `UploadFile`: `file.upload(url)` sends it and keeps
 * `file.progress` up to date, which the upload queue shows.
 */
export type UploadFn<T = unknown> = (file: UploadFile) => Promise<T>

/** Where a file is: kept in the value, uploading, or failed to upload. As upstream's Attachment. */
export type FileState = 'done' | 'uploading' | 'error'

/** A file in the value, as the file list shows it. */
export interface FileEntry<T> {
  /** What the value holds for it: the `File`, or what `@upload` resolved to. */
  value: T
  /** Its name. */
  name: string
  /** Its kind, from its extension: `PDF`, `PNG`, or `FILE`. */
  kind: string
  /** Its size, formatted (`184.3 kB`), or `undefined` when the value has none. */
  size: string | undefined
  /** A URL of an image of it, or `undefined` when there is none to show. */
  preview: string | undefined
}

/** A chosen file that is uploading, or whose upload failed: an entry in the upload queue. */
export class Upload {
  /** `uploading`, or `error` once its upload has failed. */
  @tracked state: 'uploading' | 'error' = 'uploading'
  /** Why its upload failed. */
  @tracked error: string | undefined
  /** ember-file-upload's file. */
  readonly file: UploadFile

  constructor(file: UploadFile) {
    this.file = file
  }

  /** Its name. */
  get name(): string {
    return this.file.name
  }

  /** How much of it has uploaded, from 0 to 100: ember-file-upload's `progress`. */
  get progress(): number {
    return this.file.progress
  }
}

/** What the state reads from the component's arguments, each read live. */
export interface FileUploadStateOptions<T> {
  multiple: () => boolean | undefined
  accept: () => string | undefined
  disabled: () => boolean | undefined
  value: () => readonly T[] | undefined
  defaultValue: () => readonly T[] | undefined
  onValueChange: () => ((value: T[]) => void) | undefined
  upload: () => UploadFn<T> | undefined
  queue: () => Queue | undefined
  nameOf: () => ((value: T) => string) | undefined
  sizeOf: () => ((value: T) => number | undefined) | undefined
  previewOf: () => ((value: T) => string | undefined) | undefined
  uploadFailedLabel: () => string | undefined
  locale: () => string | undefined
}

/** Which list a removal happened in, and where, so focus can move to the row that took its place. */
export interface FocusRequest {
  list: 'list' | 'queue'
  index: number
}

let nextQueue = 0

function isImage(value: unknown): value is Blob {
  return value instanceof Blob && value.type.startsWith('image/')
}

/** A value's name when the caller gives no `@nameOf`: a file's, or a record's `name` or `label`. */
function defaultName(value: unknown): string {
  if (value instanceof File) return value.name
  if (value && typeof value === 'object') {
    const { name, label } = value as { name?: unknown; label?: unknown }
    if (typeof name === 'string') return name
    if (typeof label === 'string') return label
  }
  return String(value)
}

/** A value's size in bytes when the caller gives no `@sizeOf`: its `size`, if it is a number. */
function defaultSize(value: unknown): number | undefined {
  const size = (value as { size?: unknown } | null | undefined)?.size
  return typeof size === 'number' ? size : undefined
}

/**
 * The state of a `<FileUpload>`: the files its value holds, the uploads in its queue, and what
 * its last drop turned away. Its parts read it, and act through it.
 */
export class FileUploadState<T> {
  readonly #options: FileUploadStateOptions<T>
  /** The value: what the list shows. */
  readonly value: ControllableState<readonly T[]>
  /** The queue ember-file-upload puts the chosen files in, unless the caller gave one. */
  readonly #ownQueue: Queue
  /** Previews made for image files, each an object URL, revoked when the component goes. */
  readonly #previews = new Map<Blob, string>()

  /** The uploads in flight or failed, in the order the files were chosen. */
  @tracked uploads: readonly Upload[] = []
  /** The names of the files the last drop turned away, as `@accept` doesn't take them. */
  @tracked rejected: readonly string[] = []
  /** Where focus goes once a removal has rendered. */
  @tracked focusRequest: FocusRequest | undefined
  #destroyed = false

  constructor(owner: object, options: FileUploadStateOptions<T>) {
    this.#options = options
    this.value = new ControllableState<readonly T[]>({
      name: 'value',
      value: options.value,
      defaultValue: options.defaultValue,
      onChange: options.onValueChange as () => ((value: readonly T[]) => void) | undefined,
      fallback: [],
    })
    // The queue isn't the app's `file-queue` service's, so the component needs no service and a
    // test's files never meet another's. Pass `@queue` to use one of the service's.
    this.#ownQueue = new Queue({
      name: `joinery-file-upload-${nextQueue++}`,
      fileQueue: undefined as unknown as FileQueueService,
    })
    registerDestructor(owner, () => {
      this.#destroyed = true
      for (const url of this.#previews.values()) URL.revokeObjectURL(url)
      this.#previews.clear()
      for (const file of this.#ownQueue.files) this.#ownQueue.remove(file)
    })
  }

  /** The ember-file-upload queue the chosen files go into: `@queue`, or the component's own. */
  get queue(): Queue {
    return this.#options.queue() ?? this.#ownQueue
  }

  /** Whether it takes more than one file. */
  get multiple(): boolean {
    return Boolean(this.#options.multiple())
  }

  /** Which files it takes (`@accept`). */
  get accept(): string | undefined {
    return this.#options.accept()
  }

  /** Whether it takes no files and removes none. */
  get disabled(): boolean {
    return Boolean(this.#options.disabled())
  }

  /** Whether any upload is still running. */
  get isUploading(): boolean {
    return this.uploads.some(upload => upload.state === 'uploading')
  }

  /** The value's files, as the list shows them. */
  get files(): FileEntry<T>[] {
    const nameOf = this.#options.nameOf() ?? defaultName
    const sizeOf = this.#options.sizeOf() ?? defaultSize
    const previewOf = this.#options.previewOf() ?? ((value: T) => this.#preview(value))
    const locale = this.#options.locale()
    return this.value.value.map(value => {
      const name = nameOf(value)
      const bytes = sizeOf(value)
      return {
        value,
        name,
        kind: fileKind(name),
        size: bytes === undefined ? undefined : formatFileSize(bytes, locale),
        preview: previewOf(value),
      }
    })
  }

  /** The values the list holds, as `@value` hands them over. */
  get values(): readonly T[] {
    return this.value.value
  }

  /** A file's size, formatted in the component's locale. */
  sizeOf = (file: UploadFile | File): string => formatFileSize(file.size, this.#options.locale())

  /** A preview of a file being uploaded: an object URL for an image, else `undefined`. */
  previewOf = (file: UploadFile): string | undefined => this.#preview(file.file)

  /** An object URL showing an image file, made once per file. */
  #preview(value: unknown): string | undefined {
    if (!isImage(value) || this.#destroyed) return undefined
    let url = this.#previews.get(value)
    if (!url) {
      url = URL.createObjectURL(value)
      this.#previews.set(value, url)
    }
    return url
  }

  #forget(value: unknown): void {
    if (!(value instanceof Blob)) return
    const url = this.#previews.get(value)
    if (url) URL.revokeObjectURL(url)
    this.#previews.delete(value)
  }

  /** What the picker and the drop zone may take: ember-file-upload's `filter`. */
  filter = (file: File, _files: File[], index: number): boolean => {
    if (this.disabled) return false
    if (!this.multiple && index > 0) return false
    return acceptsFile(file, this.accept)
  }

  /** Files dropped on the zone: those that passed `filter`, and the whole drop. */
  onDrop = (files: UploadFile[], transfer: { files: File[] }): void => {
    const taken = new Set(files.map(file => file.file))
    this.rejected = this.disabled
      ? []
      : transfer.files
          .filter((file, index) => !taken.has(file) && (this.multiple || index === 0))
          .map(file => file.name)
    this.take(files)
  }

  /** Files chosen in the file picker, which has filtered them already. */
  onSelect = (files: UploadFile[]): void => {
    this.rejected = []
    this.take(files)
  }

  /** Keeps the files, or, with `@upload`, queues them and uploads each. */
  take(files: UploadFile[]): void {
    if (!files.length) return
    const upload = this.#options.upload()
    if (!upload) {
      for (const file of files) this.queue.remove(file)
      this.#store(files.map(file => file.file as T))
      return
    }
    const fresh = files.map(file => new Upload(file))
    this.uploads = this.multiple ? [...this.uploads, ...fresh] : fresh
    for (const entry of fresh) void this.#send(entry, upload)
  }

  async #send(entry: Upload, upload: UploadFn<T>): Promise<void> {
    entry.state = 'uploading'
    entry.error = undefined
    try {
      const result = await upload(entry.file)
      if (this.#destroyed || !this.uploads.includes(entry)) return
      this.uploads = this.uploads.filter(other => other !== entry)
      this.queue.remove(entry.file)
      if ((result as unknown) !== entry.file.file) this.#forget(entry.file.file)
      this.#store([result])
    } catch (error) {
      if (this.#destroyed) return
      entry.state = 'error'
      entry.error =
        error instanceof Error && error.message
          ? error.message
          : typeof error === 'string' && error
            ? error
            : (this.#options.uploadFailedLabel() ?? 'Upload failed')
    }
  }

  #store(values: T[]): void {
    if (this.multiple) this.value.set(current => [...current, ...values])
    else {
      for (const old of this.value.value) this.#forget(old)
      this.value.set(values.slice(-1))
    }
  }

  /** Takes a file out of the value. Focus moves to the row that takes its place. */
  remove = (value: T): void => {
    if (this.disabled) return
    const index = this.value.value.indexOf(value)
    if (index === -1) return
    this.#forget(value)
    this.value.set(current => current.filter(other => other !== value))
    this.focusRequest = { list: 'list', index }
  }

  /** Empties the value. */
  clear = (): void => {
    if (this.disabled) return
    for (const value of this.value.value) this.#forget(value)
    this.value.set([])
  }

  /** Uploads a failed file again. */
  retry = (entry: Upload): void => {
    const upload = this.#options.upload()
    if (upload && !this.disabled) void this.#send(entry, upload)
  }

  /** Takes a file out of the upload queue, uploading or failed; its result, if any, is dropped. */
  dismiss = (entry: Upload): void => {
    const index = this.uploads.indexOf(entry)
    if (index === -1) return
    this.uploads = this.uploads.filter(other => other !== entry)
    this.queue.remove(entry.file)
    this.#forget(entry.file.file)
    this.focusRequest = { list: 'queue', index }
  }
}
