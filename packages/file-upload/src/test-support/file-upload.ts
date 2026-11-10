import { settled, triggerEvent, waitUntil } from '@ember/test-helpers'
import { ButtonHarness, Harness, ItemHarness, ProgressHarness } from '@ember-joinery/test-support'

const collapse = (value: string | null | undefined): string =>
  (value ?? '').replace(/\s+/g, ' ').trim()

/** A drag's data, as the desktop sends it: the files, typed `Files`. */
function transferOf(files: File[]): DataTransfer {
  const transfer = new DataTransfer()
  for (const file of files) transfer.items.add(file)
  return transfer
}

function dispatch(target: Element, type: string, files: File[]): void {
  target.dispatchEvent(
    new DragEvent(type, { bubbles: true, cancelable: true, dataTransfer: transferOf(files) }),
  )
}

/**
 * Drives one row of a `<FileUpload>`'s file list or upload queue: a shadcn Item, so everything
 * `ItemHarness` reads it reads too. Find one by its file's name:
 *
 *   const cv = upload.file('cv.pdf')
 *   assert.strictEqual(cv.details, 'PDF · 184.3 kB')
 *   await cv.remove()
 */
export class FileUploadItemHarness extends ItemHarness {
  /** The file's name. */
  get fileName(): string {
    return this.title
  }

  /** `done` (in the list), `uploading` or `error` (in the queue): its `data-state`. */
  get state(): string | null {
    return this.element.getAttribute('data-state')
  }

  /** What it says under the name: its kind and size (`PDF · 184.3 kB`), or a failed upload's error. */
  get details(): string {
    return this.description
  }

  /** The preview's image URL, or `null` when it shows an icon for its kind. */
  get preview(): string | null {
    return this.queryPart('media')?.querySelector('img')?.getAttribute('src') ?? null
  }

  /** Whether it shows a preview of the image rather than an icon. */
  get hasPreview(): boolean {
    return this.preview !== null
  }

  /** Whether it has a remove button: a disabled `<FileUpload>` shows none. */
  get canRemove(): boolean {
    return this.find(ButtonHarness, 'remove').exists
  }

  /** Its remove button. */
  get removeButton(): ButtonHarness {
    return this.find(ButtonHarness, 'remove')
  }

  /** A failed upload's retry button. */
  get retryButton(): ButtonHarness {
    return this.find(ButtonHarness, 'retry')
  }

  /** While it uploads, its progress bar (a `ProgressHarness`). */
  get progressBar(): ProgressHarness {
    return this.find(ProgressHarness)
  }

  /** While it uploads, how much has gone, from 0 to 100. `null` once it isn't uploading. */
  get progress(): number | null {
    const bar = this.progressBar
    return bar.exists ? bar.value : null
  }

  /** Presses its remove button. */
  async remove(): Promise<void> {
    await this.removeButton.click()
  }

  /** Presses a failed upload's retry button. */
  async retry(): Promise<void> {
    await this.retryButton.click()
  }
}

/**
 * Drives a `<FileUpload>` from `@ember-joinery/file-upload`: chooses files as the file picker
 * does, drags and drops them on its zone, and reads and removes what its list and upload queue
 * show.
 *
 *   const resume = new FileUploadHarness('resume') // <FileUpload @name="resume">
 *   await resume.select(new File(['%PDF'], 'cv.pdf', { type: 'application/pdf' }))
 *   assert.deepEqual(resume.files, ['cv.pdf'])
 *   await resume.remove('cv.pdf')
 *
 * `select` and `drop` don't wait for `@upload`; `waitForUploads()` does.
 */
export class FileUploadHarness extends Harness {
  static override component = 'file-upload'

  /** The zone files are dropped on. */
  get dropzone(): HTMLElement {
    return this.part('dropzone')
  }

  /** The zone's visually hidden `<input type="file">`. */
  get input(): HTMLInputElement {
    return this.part<HTMLInputElement>('input')
  }

  /** What the zone says, which names its input unless `@label` does. */
  get text(): string {
    const label = this.dropzone.querySelector('[data-slot="file-upload-dropzone-label"]')
    return collapse(label?.textContent)
  }

  /** The input's accessible name: its `aria-label`, else the zone's text. */
  get label(): string {
    return this.input.getAttribute('aria-label') ?? this.text
  }

  /** Which files it takes (`accept`), or `''` for any. */
  get accept(): string {
    return this.input.accept
  }

  /** Whether it takes more than one file. */
  get isMultiple(): boolean {
    return this.input.multiple
  }

  /** Whether it takes no files (its input is disabled). */
  get isDisabled(): boolean {
    return this.input.disabled
  }

  /** Whether files are dragged over its zone (`data-dragging`). */
  get isDragging(): boolean {
    return this.dropzone.hasAttribute('data-dragging')
  }

  /** Whether its input has focus, which is how a keyboard user reaches the zone. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.input
  }

  /** Whether an upload is running: it is `aria-busy`. */
  get isUploading(): boolean {
    return this.element.getAttribute('aria-busy') === 'true'
  }

  /** What the zone says about the files the last drop turned away, or `undefined`. */
  get rejected(): string | undefined {
    const message = this.queryPart('rejected')
    return message ? collapse(message.textContent) : undefined
  }

  /** The file list, or `null` while it holds nothing. */
  get list(): HTMLElement | null {
    return this.queryPart('list')
  }

  /** The upload queue, or `null` while nothing uploads or has failed. */
  get queue(): HTMLElement | null {
    return this.queryPart('queue')
  }

  /** Every row, the list's and the queue's, in the order they show. */
  get items(): FileUploadItemHarness[] {
    return this.findAll(FileUploadItemHarness)
  }

  /** The names in the file list: the files the value holds. */
  get files(): string[] {
    return this.#named('done')
  }

  /** The names of the files uploading. */
  get uploading(): string[] {
    return this.#named('uploading')
  }

  /** The names of the files whose upload failed. */
  get failed(): string[] {
    return this.#named('error')
  }

  #named(state: string): string[] {
    return this.items.filter(item => item.state === state).map(item => item.fileName)
  }

  /** The row of the file with this name. */
  file(name: string): FileUploadItemHarness {
    return this.find(FileUploadItemHarness, name)
  }

  /** Chooses files in the file picker: its input's `change`. Doesn't wait for `@upload`. */
  async select(...files: File[]): Promise<void> {
    await triggerEvent(this.input, 'change', { files })
  }

  /** Drags files from the desktop over the zone. */
  async drag(...files: File[]): Promise<void> {
    dispatch(this.dropzone, 'dragenter', files)
    dispatch(this.dropzone, 'dragover', files)
    await settled()
  }

  /** Drags them away again. */
  async leave(): Promise<void> {
    dispatch(this.dropzone, 'dragleave', [])
    await settled()
  }

  /** Drags files from the desktop and drops them on the zone. Doesn't wait for `@upload`. */
  async drop(...files: File[]): Promise<void> {
    dispatch(this.dropzone, 'dragenter', files)
    dispatch(this.dropzone, 'dragover', files)
    dispatch(this.dropzone, 'drop', files)
    await settled()
  }

  /** Presses the remove button of the file with this name. */
  async remove(name: string): Promise<void> {
    await this.file(name).remove()
  }

  /** Presses Retry on the failed upload with this name. */
  async retry(name: string): Promise<void> {
    await this.file(name).retry()
  }

  /** Waits until no file is uploading: each is in the list, or has failed. */
  async waitForUploads(): Promise<void> {
    await waitUntil(() => this.uploading.length === 0, {
      timeoutMessage: `Joinery harness: the uploads in ${this} never finished`,
    })
    await settled()
  }
}
