import {
  after,
  always,
  invoke,
  Machine,
  onEntry,
  onExit,
  State,
  transition,
} from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'
import { buildWaiter } from '@ember/test-waiters'

const waiter = buildWaiter('@ember-joinery/primitives:avatar')

export class ImageState extends State {
  declare private readonly brand: never
  /** No image to load: on a server. */
  static Idle = ImageState.of('idle')
  /** The browser fetches it. */
  static Loading = ImageState.of('loading')
  static Loaded = ImageState.of('loaded')
  /** It failed, or there was no `src`. */
  static Error = ImageState.of('error')
}

/**
 * One image's loading, as Radix's `useImageLoadingStatus`: an image the browser has already is
 * loaded at once; otherwise it loads until its `load` or `error` event. Without an image it is
 * an error, unless `missing` is false (a server, where it stays idle). Tests wait while it loads.
 */
export class ImageMachine extends Machine<ImageState> {
  readonly image: HTMLImageElement | undefined
  readonly missing: boolean
  readonly settled: (status: 'loaded' | 'error') => void
  #token: unknown

  constructor(
    image: HTMLImageElement | undefined,
    missing: boolean,
    settled: (status: 'loaded' | 'error') => void,
  ) {
    super()
    this.image = image
    this.missing = missing
    this.settled = settled
  }

  get isComplete(): boolean {
    return Boolean(this.image?.complete && this.image.naturalWidth > 0)
  }

  get hasImage(): boolean {
    return this.image !== undefined
  }

  get isMissing(): boolean {
    return this.missing
  }

  @always({
    from: ImageState.Idle,
    to: ImageState.Loaded,
    guard: (m: ImageMachine) => m.isComplete,
  })
  @always({ from: ImageState.Idle, to: ImageState.Loading, guard: (m: ImageMachine) => m.hasImage })
  @always({ from: ImageState.Idle, to: ImageState.Error, guard: (m: ImageMachine) => m.isMissing })
  begin() {}

  @transition({ from: ImageState.Loading, to: ImageState.Loaded })
  loaded() {}

  @transition({ from: ImageState.Loading, to: ImageState.Error })
  failed() {}

  /** Listens to the image while it loads; the cleanup stops listening. */
  @invoke(ImageState.Loading)
  listen(): () => void {
    const image = this.image!
    const loaded = () => this.loaded()
    const failed = () => this.failed()
    image.addEventListener('load', loaded)
    image.addEventListener('error', failed)
    return () => {
      image.removeEventListener('load', loaded)
      image.removeEventListener('error', failed)
    }
  }

  // A waiter of its own, not the invoke's: stopping the machine ends the wait at once.
  @onEntry(ImageState.Loading)
  wait() {
    this.#token = waiter.beginAsync()
  }

  @onExit(ImageState.Loading)
  endWait() {
    if (this.#token === undefined) return
    waiter.endAsync(this.#token)
    this.#token = undefined
  }

  @onEntry(ImageState.Loaded)
  onLoaded() {
    this.settled('loaded')
  }

  @onEntry(ImageState.Error)
  onError() {
    this.settled('error')
  }
}

export class FallbackState extends State {
  declare private readonly brand: never
  /** Waiting out `delayMs`. */
  static Waiting = FallbackState.of('waiting')
  /** The fallback may show, for good. */
  static Ready = FallbackState.of('ready')
}

/** What a fallback's delay reads. */
export interface FallbackHost {
  readonly delayMs: number | undefined
}

/**
 * An avatar fallback's `@delayMs`, as Radix's: it waits that long before it may show. A new
 * delay while it waits starts the wait over, taking it away ends the wait, and once it has run
 * out a new one changes nothing.
 */
export class FallbackDelay extends Machine<FallbackState> {
  readonly host: FallbackHost

  constructor(host: FallbackHost) {
    super()
    this.host = host
  }

  get delayMs(): number {
    return this.host.delayMs ?? 0
  }

  get hasNoDelay(): boolean {
    return this.host.delayMs === undefined
  }

  get isWaiting(): boolean {
    return this.matches(FallbackState.Waiting)
  }

  @always({
    from: FallbackState.Waiting,
    to: FallbackState.Ready,
    guard: (m: FallbackDelay) => m.hasNoDelay,
  })
  undelayed() {}

  /** `delayMs` changed. */
  @transition({
    from: FallbackState.Waiting,
    to: FallbackState.Ready,
    guard: (m: FallbackDelay) => m.hasNoDelay,
  })
  @transition({ from: FallbackState.Waiting, to: FallbackState.Waiting, reenter: true })
  @transition({})
  delayChanged() {}

  @after('delayMs', { from: FallbackState.Waiting, to: FallbackState.Ready })
  waited() {}
}

/** A started `FallbackDelay`, stopped (its timer with it) when `owner` is destroyed. */
export function fallbackDelay(owner: object, host: FallbackHost): FallbackDelay {
  return machine(owner, new FallbackDelay(host))
}
