import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** Where an avatar's image is, as the primitives' `ImageLoadingStatus` names it. */
export type AvatarStatus = 'idle' | 'loading' | 'loaded' | 'error'

/**
 * Drives an `<Avatar>` from `@ember-joinery/ember`, or the headless one from
 * `@ember-joinery/primitives/avatar`. It reads where the image is, and what shows: the image
 * once it has loaded, the fallback until then and if it fails.
 *
 *   const avatar = new AvatarHarness('shadcn') // <Avatar @name="shadcn">
 *   assert.true(avatar.isLoaded)
 *   assert.strictEqual(avatar.label, '@shadcn') // the image's alt
 *
 * Tests wait for the image (`settled()` resolves once it has loaded or failed), so after
 * `render()` the status is `loaded` or `error`.
 */
export class AvatarHarness extends Harness {
  static override component = 'avatar'

  /**
   * Where the image is: `loaded` when it shows, `loading` or `error` from the avatar's
   * `data-loading` and `data-error`, and `idle` with no image to load.
   */
  get status(): AvatarStatus {
    if (this.image) return 'loaded'
    const element = this.element
    if (element.hasAttribute('data-error')) return 'error'
    if (element.hasAttribute('data-loading')) return 'loading'
    return 'idle'
  }

  /** Whether the image has loaded, and shows. */
  get isLoaded(): boolean {
    return this.status === 'loaded'
  }

  /** Whether the image is loading. */
  get isLoading(): boolean {
    return this.status === 'loading'
  }

  /** Whether the image failed to load. */
  get isError(): boolean {
    return this.status === 'error'
  }

  /** The `<img>`, once it has loaded, or `null`. */
  get image(): HTMLImageElement | null {
    return this.queryPart<HTMLImageElement>('image')
  }

  /** The fallback while it shows, or `null`. */
  get fallback(): HTMLElement | null {
    return this.queryPart('fallback')
  }

  /** The fallback's text (`CN`), or `''` while it doesn't show. */
  get fallbackText(): string {
    return text(this.fallback)
  }

  /** The image's URL, once it has loaded, or `null`. */
  get src(): string | null {
    return this.image?.getAttribute('src') ?? null
  }

  /**
   * What it stands for, as a screen reader reads it: the image's `alt` once it shows, else the
   * fallback's text.
   */
  get label(): string {
    const image = this.image
    if (image) return image.getAttribute('alt') ?? ''
    return this.fallbackText
  }

  /** Its `@size`: `default`, `sm` or `lg`. `null` for the headless avatar, which has none. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** The badge, or `null` without one. */
  get badge(): HTMLElement | null {
    return this.queryPart('badge')
  }

  /** Whether it has a badge. */
  get hasBadge(): boolean {
    return this.badge !== null
  }
}

/**
 * Drives an `<AvatarGroup>` from `@ember-joinery/ember`: its avatars, in order, and its count.
 *
 *   const team = new AvatarGroupHarness('team')
 *   assert.strictEqual(team.avatars.length, 3)
 *   assert.strictEqual(team.count, '+3')
 */
export class AvatarGroupHarness extends Harness {
  static override component = 'avatar-group'

  /** A harness for each avatar in the group, in order. */
  get avatars(): AvatarHarness[] {
    return this.findAll(AvatarHarness)
  }

  /** The count's text (`+3`), `''` for one that shows an icon, or `null` without a count. */
  get count(): string | null {
    const count = this.queryPart('count')
    return count ? text(count) : null
  }

  /** The count element, or `null` without one. */
  get countElement(): HTMLElement | null {
    return this.queryPart('count')
  }
}
