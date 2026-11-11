import { cached, tracked } from '@glimmer/tracking'
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
  /** Its kind, from its extension: `PDF`, `PNG`, or `@unknownKindLabel` (`FILE`) without one. */
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
  uploadFailedLabel: () => string
  unknownKindLabel: () => string | undefined
  locale: () => string | undefined
}

/**
 * Where a row lost the button that had focus (it was removed, or a retry took its buttons away),
 * so focus can move to the nearest button of the same kind once that has rendered.
 */
export interface FocusRequest {
  /** The list it happened in. */
  list: 'list' | 'queue'
  /** The row's index: the row that took its place, or the row itself. */
  index: number
  /** The kind of button that had focus. */
  button: 'remove' | 'retry'
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
  /** The names of the files the last choice or drop turned away, as `@accept` doesn't take them. */
  @tracked rejected: readonly string[] = []
  /** The names of the files the last choice or drop left out, without `@multiple`: all but one. */
  @tracked leftOut: readonly string[] = []
  /** Where focus goes once a removal or a retry has rendered. */
  @tracked focusRequest: FocusRequest | undefined
  /** What `filter` has turned away from the choice or drop being taken, for its message. */
  #unaccepted: string[] = []
  #extra: string[] = []
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
      // Its uploads leave whichever queue they are in, `@queue` included: nothing will settle them.
      for (const entry of this.uploads) entry.file.queue?.remove(entry.file)
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

  /**
   * The value's files, as the list shows them. Cached, so they are the same objects until the
   * value (or how it is named, sized or previewed) changes; the list keys its rows on `value`, so
   * a row, and the focus on its button, stays put when another file comes or goes.
   */
  @cached
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
        kind: this.kindOf(name),
        size: bytes === undefined ? undefined : formatFileSize(bytes, locale),
        preview: previewOf(value),
      }
    })
  }

  /** A file's kind, from its name: `PDF`, or `@unknownKindLabel` (`FILE`) without an extension. */
  kindOf = (name: string): string => fileKind(name, this.#options.unknownKindLabel())

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

  /**
   * Revokes the previews of the files that are neither in the value nor in the queue. It runs
   * after each change, so in controlled mode a removal the caller refuses keeps its preview: the
   * value still holds the file.
   */
  #sweep(): void {
    if (!this.#previews.size) return
    const kept = new Set<unknown>(this.value.value)
    for (const entry of this.uploads) kept.add(entry.file.file)
    for (const [blob, url] of this.#previews) {
      if (kept.has(blob)) continue
      URL.revokeObjectURL(url)
      this.#previews.delete(blob)
    }
  }

  /**
   * What the picker and the drop zone may take: ember-file-upload's `filter`. It notes what it
   * turns away, which `onSelect` and `onDrop` then name.
   */
  filter = (file: File, _files: File[], index: number): boolean => {
    if (this.disabled) return false
    if (!this.multiple && index > 0) {
      this.#extra.push(file.name)
      return false
    }
    if (acceptsFile(file, this.accept)) return true
    this.#unaccepted.push(file.name)
    return false
  }

  /**
   * Files dropped on the zone: those that passed `filter`, and the whole drop. Without
   * `@multiple`, ember-file-upload's zone offers `filter` only the first file, so the rest are
   * named as left out here.
   */
  onDrop = (files: UploadFile[], transfer: { files: File[] }): void => {
    if (!this.multiple && !this.disabled) {
      this.#extra.push(...transfer.files.slice(1).map(file => file.name))
    }
    this.#report()
    this.take(files)
  }

  /**
   * Files chosen in the file picker. Its `accept` filters what the dialog shows, but a choice of
   * "All files" there lets anything through, so `filter` checks them again and they are named as
   * a drop's are.
   */
  onSelect = (files: UploadFile[]): void => {
    this.#report()
    this.take(files)
  }

  /** Names what `filter` turned away from the choice or drop just taken, and starts afresh. */
  #report(): void {
    this.rejected = this.#unaccepted
    this.leftOut = this.#extra
    this.#unaccepted = []
    this.#extra = []
  }

  /**
   * Keeps the files, or, with `@upload`, queues them and uploads each. Without `@multiple`, a new
   * file replaces the one uploading or failed: that one leaves ember-file-upload's queue, and
   * whatever its upload resolves to is dropped.
   */
  take(files: UploadFile[]): void {
    if (!files.length) return
    const upload = this.#options.upload()
    if (!upload) {
      for (const file of files) file.queue?.remove(file)
      this.#store(files.map(file => file.file as T))
      return
    }
    const fresh = files.map(file => new Upload(file))
    if (this.multiple) this.uploads = [...this.uploads, ...fresh]
    else {
      for (const old of this.uploads) old.file.queue?.remove(old.file)
      this.uploads = fresh
      this.#sweep()
    }
    for (const entry of fresh) void this.#send(entry, upload)
  }

  async #send(entry: Upload, upload: UploadFn<T>): Promise<void> {
    entry.state = 'uploading'
    entry.error = undefined
    try {
      const result = await upload(entry.file)
      if (this.#destroyed || !this.uploads.includes(entry)) return
      this.uploads = this.uploads.filter(other => other !== entry)
      entry.file.queue?.remove(entry.file)
      this.#store([result])
    } catch (error) {
      if (this.#destroyed || !this.uploads.includes(entry)) return
      entry.state = 'error'
      entry.error =
        error instanceof Error && error.message
          ? error.message
          : typeof error === 'string' && error
            ? error
            : this.#options.uploadFailedLabel()
    }
  }

  #store(values: T[]): void {
    if (this.multiple) this.value.set(current => [...current, ...values])
    else this.value.set(values.slice(-1))
    this.#sweep()
  }

  /** Takes a file out of the value. Focus moves to the row that takes its place. */
  remove = (value: T): void => {
    if (this.disabled) return
    const index = this.value.value.indexOf(value)
    if (index === -1) return
    this.value.set(current => current.filter(other => other !== value))
    this.#sweep()
    this.focusRequest = { list: 'list', index, button: 'remove' }
  }

  /** Empties the value. */
  clear = (): void => {
    if (this.disabled) return
    this.value.set([])
    this.#sweep()
  }

  /**
   * Uploads a failed file again. Its row loses its buttons while it uploads, so focus moves to
   * the nearest row's Retry (or remove) button, else to the file input.
   */
  retry = (entry: Upload): void => {
    const upload = this.#options.upload()
    const index = this.uploads.indexOf(entry)
    if (!upload || this.disabled || index === -1 || entry.state !== 'error') return
    void this.#send(entry, upload)
    this.focusRequest = { list: 'queue', index, button: 'retry' }
  }

  /** Takes a file out of the upload queue, uploading or failed; its result, if any, is dropped. */
  dismiss = (entry: Upload): void => {
    if (this.disabled) return
    const index = this.uploads.indexOf(entry)
    if (index === -1) return
    this.uploads = this.uploads.filter(other => other !== entry)
    entry.file.queue?.remove(entry.file)
    this.#sweep()
    this.focusRequest = { list: 'queue', index, button: 'remove' }
  }
}
