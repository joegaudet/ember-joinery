/* global ReferrerPolicy -- a DOM type, which ESLint's browser globals don't list */
import Component from '@glimmer/component'
import { cached, tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { buildWaiter, waitForPromise } from '@ember/test-waiters'
import type Owner from '@ember/owner'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'

/**
 * Where an avatar's image is: Radix's `ImageLoadingStatus`. `idle` until there is an image to
 * load, `loading` while the browser fetches it, then `loaded` or `error`.
 */
export type ImageLoadingStatus = 'idle' | 'loading' | 'loaded' | 'error'

/** How an image is fetched: the `<img>` attributes of the same names. */
export interface ImageLoaderOptions {
  /** `anonymous` or `use-credentials`, for an image from another origin. */
  crossOrigin?: string
  /** What the request tells the image's server about the page. */
  referrerPolicy?: ReferrerPolicy
}

const waiter = buildWaiter('@ember-joinery/primitives:avatar')

/**
 * Loads one image off the page, as Radix's `useImageLoadingStatus` does: an `Image` the page
 * never shows, whose `load` and `error` events set `status`. A cached image is `loaded` at
 * once; one with no `src` is an `error`; on a server (no `Image`) it stays `idle`.
 *
 *   const loader = new ImageLoader('https://github.com/shadcn.png')
 *   loader.status // 'loading', then 'loaded'
 *   loader.destroy()
 *
 * Tests wait for it: `settled()` resolves once the image has loaded or failed.
 */
export class ImageLoader {
  /** Where the image is. Tracked: a template that reads it updates when the image settles. */
  @tracked status: ImageLoadingStatus
  readonly src: string | undefined
  #image: HTMLImageElement | undefined
  #token: unknown
  #listeners = new Set<(status: ImageLoadingStatus) => void>()

  constructor(src: string | undefined | null, options: ImageLoaderOptions = {}) {
    this.src = src ?? undefined
    if (typeof window === 'undefined' || typeof window.Image === 'undefined') {
      this.status = 'idle'
      return
    }
    if (!src) {
      this.status = 'error'
      return
    }
    const image = new window.Image()
    if (options.referrerPolicy) image.referrerPolicy = options.referrerPolicy
    if (typeof options.crossOrigin === 'string') image.crossOrigin = options.crossOrigin
    image.addEventListener('load', this.#onLoad)
    image.addEventListener('error', this.#onError)
    image.src = src
    this.#image = image
    // The browser fires `load` or `error` even for an image it has already, so the waiter
    // always ends.
    this.#token = waiter.beginAsync()
    this.status = image.complete && image.naturalWidth > 0 ? 'loaded' : 'loading'
  }

  /** Calls `listener` with each new status, until the returned function is called. */
  subscribe(listener: (status: ImageLoadingStatus) => void): () => void {
    this.#listeners.add(listener)
    return () => void this.#listeners.delete(listener)
  }

  /** Stops listening to the image, and lets tests stop waiting for it. */
  destroy(): void {
    this.#image?.removeEventListener('load', this.#onLoad)
    this.#image?.removeEventListener('error', this.#onError)
    this.#image = undefined
    this.#listeners.clear()
    this.#end()
  }

  #onLoad = (): void => this.#settle('loaded')
  #onError = (): void => this.#settle('error')

  #settle(status: ImageLoadingStatus): void {
    this.#end()
    if (this.status === status) return
    this.status = status
    for (const listener of this.#listeners) listener(status)
  }

  #end(): void {
    if (this.#token === undefined) return
    waiter.endAsync(this.#token)
    this.#token = undefined
  }
}

/**
 * Runs `callback` after the current render: an image tells its avatar about itself while it
 * renders, and Ember forbids changing tracked state the same render has read. Tests wait for it.
 */
function afterRender(callback: () => void): void {
  void waitForPromise(Promise.resolve().then(callback))
}

export interface AvatarImageSignature {
  Args: {
    /**
     * The image's URL. Without it, the image shows the avatar's `@src`. The `<img>` renders
     * only once the image has loaded, so the fallback shows until then.
     */
    src?: string
    /** `<img crossorigin>`: `anonymous` or `use-credentials`, for an image from another origin. */
    crossOrigin?: string
    /** `<img referrerpolicy>`: what the request tells the image's server about the page. */
    referrerPolicy?: ReferrerPolicy
    /** Called with each new status of this image: `loading`, then `loaded` or `error`. */
    onLoadingStatusChange?: (status: ImageLoadingStatus) => void
    /** @private Bound by `Avatar`. */
    avatar: Avatar
  }
  /** Give it `alt`: the image stands for a person, so it needs a name. */
  Element: HTMLImageElement
}

/** The avatar's image: an `<img>` once its image has loaded, and nothing before. */
class AvatarImage extends Component<AvatarImageSignature> {
  #loader: ImageLoader | undefined
  #unsubscribe: (() => void) | undefined

  constructor(owner: Owner, args: AvatarImageSignature['Args']) {
    super(owner, args)
    registerDestructor(this, () => {
      this.#release()
      this.args.avatar.disconnect(this)
    })
  }

  /** The URL it shows: its own `@src`, else the avatar's. */
  get src(): string | undefined {
    return this.args.src ?? this.args.avatar.args.src
  }

  /**
   * What loads it: the avatar's own loader when the image shows the avatar's `@src`, or a
   * loader of its own, which it hands the avatar so the fallback knows. Cached, so a loader
   * lives as long as the arguments it was made from, as a resource does.
   */
  @cached
  get loader(): ImageLoader | undefined {
    const { src, crossOrigin, referrerPolicy, onLoadingStatusChange } = this.args
    return this.#load(src, { crossOrigin, referrerPolicy }, onLoadingStatusChange)
  }

  /** Lets the last loader go, and loads `src` (or takes the avatar's loader without one). */
  #load(
    own: string | undefined,
    options: ImageLoaderOptions,
    changed: ((status: ImageLoadingStatus) => void) | undefined,
  ): ImageLoader | undefined {
    const avatar = this.args.avatar
    this.#release()
    let loader: ImageLoader | undefined
    if (own === undefined && avatar.args.src !== undefined) {
      loader = avatar.rootLoader
      avatar.disconnect(this)
    } else {
      loader = this.#loader = new ImageLoader(own, options)
      avatar.connect(this, loader)
    }
    if (loader && changed) {
      this.#unsubscribe = loader.subscribe(status => changed(status))
      const first = loader
      afterRender(() => {
        if (!isDestroying(this) && first.status !== 'idle') changed(first.status)
      })
    }
    return loader
  }

  get isLoaded(): boolean {
    return this.loader?.status === 'loaded'
  }

  #release(): void {
    this.#unsubscribe?.()
    this.#unsubscribe = undefined
    this.#loader?.destroy()
    this.#loader = undefined
  }

  <template>
    {{#if this.isLoaded}}
      <img
        crossorigin={{@crossOrigin}}
        referrerpolicy={{@referrerPolicy}}
        data-test-jn-part="image"
        ...attributes
        src={{this.src}}
      />
    {{/if}}
  </template>
}

export interface AvatarFallbackSignature {
  Args: {
    /**
     * How long to wait, in milliseconds, before showing the fallback, so a fast connection
     * never sees it flash. Default: show it at once.
     */
    delayMs?: number
    /** The tag to render. Default `span`. */
    as?: TagName
    /** @private Bound by `Avatar`. */
    avatar: Avatar
  }
  Blocks: {
    /** What shows instead of the image: initials, an icon. */
    default: []
  }
  Element: HTMLElement
}

/** What the avatar shows while its image loads, when it fails, and when it has none. */
class AvatarFallback extends Component<AvatarFallbackSignature> {
  // Set in the constructor: a tracked field's initializer runs on first read, too late to see
  // the starting `@delayMs`.
  @tracked private delayed: boolean
  #timer: ReturnType<typeof setTimeout> | undefined
  #token: unknown

  constructor(owner: Owner, args: AvatarFallbackSignature['Args']) {
    super(owner, args)
    const delay = args.delayMs
    this.delayed = delay !== undefined
    if (delay !== undefined) {
      this.#token = waiter.beginAsync()
      this.#timer = setTimeout(() => {
        this.#end()
        if (!isDestroying(this) && !isDestroyed(this)) this.delayed = false
      }, delay)
    }
    registerDestructor(this, () => {
      clearTimeout(this.#timer)
      this.#end()
    })
  }

  get isShown(): boolean {
    return !this.delayed && this.args.avatar.status !== 'loaded'
  }

  #end(): void {
    if (this.#token === undefined) return
    waiter.endAsync(this.#token)
    this.#token = undefined
  }

  <template>
    {{#if this.isShown}}
      <As @as={{@as}} @tag="span" data-test-jn-part="fallback" ...attributes>{{yield}}</As>
    {{/if}}
  </template>
}

export interface AvatarSignature {
  Args: {
    /**
     * The image's URL, as ember-primitives' `Avatar` takes it. The image can take its own
     * `@src` instead, as Radix's does.
     */
    src?: string
    /** The tag to render. Default `span`. */
    as?: TagName
    /** The avatar's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [
      avatar: {
        /** The image, shown once it has loaded. Give it `alt`. */
        Image: WithBoundArgs<typeof AvatarImage, 'avatar'>
        /** What shows until then, and if it fails: initials, an icon. */
        Fallback: WithBoundArgs<typeof AvatarFallback, 'avatar'>
        /** Where the image is: `idle`, `loading`, `loaded` or `error`. */
        status: ImageLoadingStatus
        /** Whether the image is loading. */
        isLoading: boolean
        /** Whether the image has loaded, and shows. */
        isLoaded: boolean
        /** Whether the image failed to load. */
        isError: boolean
      },
    ]
  }
  Element: HTMLElement
}

/**
 * An image with a fallback, for representing a user: Radix's and ember-primitives' `Avatar`.
 * The image renders only once it has loaded, and the fallback shows until then, and in its
 * place if it fails. Give the image its URL, or the avatar (ember-primitives' way):
 *
 *   <Avatar as |a|>
 *     <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
 *     <a.Fallback>CN</a.Fallback>
 *   </Avatar>
 *
 *   <Avatar @src={{this.user.photo}} as |a|>
 *     <a.Image alt={{this.user.name}} />
 *     <a.Fallback @delayMs={{600}}>{{this.user.initials}}</a.Fallback>
 *   </Avatar>
 *
 * It renders a `span` with no styles, `data-loading` while the image loads and `data-error`
 * if it fails, and yields the image's `status` (with `isLoading`, `isLoaded` and `isError`).
 * Tests wait for the image: `settled()` resolves once it has loaded or failed.
 */
export class Avatar extends Component<AvatarSignature> {
  /** Bumped to tell the template an image connected or went: see `connect`. */
  @tracked private version = 0
  // Untracked: an image connects while it renders, after the avatar has read its status.
  #connected: { image: object; loader: ImageLoader } | undefined
  #rootLoader: ImageLoader | undefined

  constructor(owner: Owner, args: AvatarSignature['Args']) {
    super(owner, args)
    registerDestructor(this, () => this.#rootLoader?.destroy())
  }

  /** The loader for the avatar's own `@src`, or none without one. Cached, as a resource. */
  @cached
  get rootLoader(): ImageLoader | undefined {
    return this.#load(this.args.src)
  }

  /** Lets the last loader go, and loads `src`. */
  #load(src: string | undefined): ImageLoader | undefined {
    this.#rootLoader?.destroy()
    this.#rootLoader = src === undefined ? undefined : new ImageLoader(src)
    return this.#rootLoader
  }

  /** Where the image is: the connected image's, else the avatar's own `@src`'s, else `idle`. */
  get status(): ImageLoadingStatus {
    void this.version
    const loader = this.#connected?.loader ?? this.rootLoader
    return loader?.status ?? 'idle'
  }

  get isLoading(): boolean {
    return this.status === 'loading'
  }

  get isLoaded(): boolean {
    return this.status === 'loaded'
  }

  get isError(): boolean {
    return this.status === 'error'
  }

  /** @private An image with a `@src` of its own hands the avatar its loader. */
  connect(image: object, loader: ImageLoader): void {
    this.#connected = { image, loader }
    this.#refresh()
  }

  /** @private An image going, or showing the avatar's own `@src` again. */
  disconnect(image: object): void {
    if (this.#connected?.image !== image) return
    this.#connected = undefined
    this.#refresh()
  }

  #refresh(): void {
    afterRender(() => {
      if (!isDestroying(this) && !isDestroyed(this)) this.version++
    })
  }

  <template>
    <As
      @as={{@as}}
      @tag="span"
      data-loading={{this.isLoading}}
      data-error={{this.isError}}
      data-test-jn="avatar"
      data-test-jn-name={{@name}}
      ...attributes
    >{{yield
        (hash
          Image=(component AvatarImage avatar=this)
          Fallback=(component AvatarFallback avatar=this)
          status=this.status
          isLoading=this.isLoading
          isLoaded=this.isLoaded
          isError=this.isError
        )
      }}</As>
  </template>
}

export default Avatar
