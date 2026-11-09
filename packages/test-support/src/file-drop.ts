import { settled, triggerEvent } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { textOf } from './-private/checkable.ts'

/** A drag's data: the files, which also make its types include `Files`. */
function transferOf(files: File[]): DataTransfer {
  const transfer = new DataTransfer()
  for (const file of files) transfer.items.add(file)
  return transfer
}

function dispatch(target: Element | Document, type: string, files: File[]): DragEvent {
  const event = new DragEvent(type, {
    bubbles: true,
    cancelable: true,
    dataTransfer: transferOf(files),
  })
  target.dispatchEvent(event)
  return event
}

/**
 * Drags `files` over `target`, as a user does from the desktop: `dragenter`, then `dragover`.
 * Returns whether the page allows a drop there (it cancelled the `dragover`).
 *
 *   await dragFilesOver(document.body, [new File(['…'], 'clip.mp4', { type: 'video/mp4' })])
 */
export async function dragFilesOver(target: Element | Document, files: File[]): Promise<boolean> {
  dispatch(target, 'dragenter', files)
  const over = dispatch(target, 'dragover', files)
  await settled()
  return over.defaultPrevented
}

/** Drags files away from `target` again: a `dragleave`. */
export async function dragFilesAway(target: Element | Document, files: File[] = []): Promise<void> {
  dispatch(target, 'dragleave', files.length ? files : [new File([], 'file')])
  await settled()
}

/**
 * Drops `files` on `target`: `dragenter`, `dragover`, then `drop`. Returns whether the page
 * took the drop (it cancelled it, so the browser doesn't open the file in the tab).
 */
export async function dropFiles(target: Element | Document, files: File[]): Promise<boolean> {
  dispatch(target, 'dragenter', files)
  dispatch(target, 'dragover', files)
  const drop = dispatch(target, 'drop', files)
  await settled()
  return drop.defaultPrevented
}

/**
 * Drives a `<FileDrop>` from `@ember-joinery/ember`, or the headless one from
 * `@ember-joinery/primitives/file-drop`: picks files as the file picker does, and drags and
 * drops them as a user does. For a `<DocumentFileDrop>`, which has no element, use
 * `dropFiles(document.body, files)`.
 *
 *   const zone = new FileDropHarness('avatar') // <FileDrop @name="avatar">
 *   await zone.drop([new File(['…'], 'me.png', { type: 'image/png' })])
 */
export class FileDropHarness extends Harness {
  static override component = 'file-drop'

  /** The text it shows, which names its input. */
  get text(): string {
    return textOf(this.element)
  }

  /** Its visually hidden `<input type="file">`. */
  get input(): HTMLInputElement {
    return this.part<HTMLInputElement>('input')
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

  /** Whether files are dragged over it (`data-dragging`). */
  get isDragging(): boolean {
    return this.element.hasAttribute('data-dragging')
  }

  /** Whether its input has focus, which is how a keyboard user reaches the zone. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.input
  }

  /** Picks `files` in the file picker: its input's `change`. */
  async pick(files: File[]): Promise<void> {
    await triggerEvent(this.input, 'change', { files })
  }

  /** Drags `files` over it. Returns whether it allows the drop. */
  async drag(files: File[]): Promise<boolean> {
    return dragFilesOver(this.element, files)
  }

  /** Drags the files away again. */
  async leave(): Promise<void> {
    await dragFilesAway(this.element)
  }

  /** Drops `files` on it. Returns whether it took the drop. */
  async drop(files: File[]): Promise<boolean> {
    return dropFiles(this.element, files)
  }
}
