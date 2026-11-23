// Importing @switchyard-ts/ember wires tracking and test waiters: `settled()` waits for uploads.
import '@switchyard-ts/ember'
import { invoke, Machine, onEntry, State, transition } from '@switchyard-ts/core'
import type { UploadFile } from 'ember-file-upload'

export class UploadState extends State {
  declare private readonly brand: never
  /** `upload(file, { signal })` is running. */
  static Uploading = UploadState.of('uploading')
  /** It rejected; `retry()` sends it again. */
  static Failed = UploadState.of('failed')
  /** It resolved, and the host has what it resolved to. */
  static Done = UploadState.of('done', { final: true })
}

/** What an upload reports to. */
export interface UploadHost<T> {
  isDisabled(): boolean
  upload(file: UploadFile, options: { signal: AbortSignal }): Promise<T>
  /** The upload resolved with `value`. */
  uploaded(value: T): void
}

/**
 * One file's upload, as a chart: it uploads, then is done or has failed, and a failed one can
 * be retried. Stopping it aborts the upload's signal, and what the upload settles with after
 * that is dropped.
 */
export class UploadActor<T> extends Machine<UploadState> {
  readonly file: UploadFile
  readonly host: UploadHost<T>
  /** What the upload resolved with, kept for `Done`'s entry. */
  result: T | undefined
  /** What the last attempt rejected with. */
  failure: unknown

  constructor(file: UploadFile, host: UploadHost<T>) {
    super()
    this.file = file
    this.host = host
  }

  get isEnabled(): boolean {
    return !this.host.isDisabled()
  }

  @invoke(UploadState.Uploading, { onDone: UploadState.Done, onError: UploadState.Failed })
  upload(signal: AbortSignal): PromiseLike<T> {
    // In a promise, so an upload that throws, or returns a plain value, is handled as `await` did.
    const sent = new Promise<T>(resolve => resolve(this.host.upload(this.file, { signal }))).then(
      value => (this.result = value),
      (error: unknown) => {
        this.failure = error
        throw error
      },
    )
    // Not a Promise, so Switchyard doesn't make it a test waiter: `settled()` doesn't wait for an
    // upload, which a test settles by hand.
    return { then: sent.then.bind(sent) }
  }

  @transition({
    from: UploadState.Failed,
    to: UploadState.Uploading,
    guard: (m: UploadActor<unknown>) => m.isEnabled,
  })
  retry() {}

  @onEntry(UploadState.Done)
  done() {
    this.host.uploaded(this.result as T)
  }
}
