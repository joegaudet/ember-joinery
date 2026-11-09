/* global ReferrerPolicy -- a DOM type, which ESLint's browser globals don't list */
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import {
  Avatar as AvatarPrimitive,
  type AvatarSignature as AvatarPrimitiveSignature,
  type ImageLoadingStatus,
} from '@ember-joinery/primitives/avatar'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'

export type { ImageLoadingStatus }

/** How big an avatar is: 32px by default, 24px `sm`, 40px `lg` (in Nova). */
export type AvatarSize = 'default' | 'sm' | 'lg'

type PrimitiveParts = AvatarPrimitiveSignature['Blocks']['default'][0]

export interface AvatarImageSignature {
  Args: {
    /** The image's URL. The `<img>` renders once it has loaded; the fallback shows until then. */
    src?: string
    /** `<img crossorigin>`, for an image from another origin. */
    crossOrigin?: string
    /** `<img referrerpolicy>`. */
    referrerPolicy?: ReferrerPolicy
    /** Called with each new status of the image: `loading`, then `loaded` or `error`. */
    onLoadingStatusChange?: (status: ImageLoadingStatus) => void
  }
  /** Give it `alt`, the person's name or handle (`alt="@shadcn"`). */
  Element: HTMLImageElement
}

export interface AvatarFallbackSignature {
  Args: {
    /** Wait this many milliseconds before showing it, so a fast connection never sees it flash. */
    delayMs?: number
    /** The tag to render. Default `span`. */
    as?: TagName
  }
  Blocks: {
    /** What shows instead of the image: initials, an icon. */
    default: []
  }
  Element: HTMLElement
}

export interface AvatarBadgeSignature {
  Args: {
    /** The tag to render. Default `span`. */
    as?: TagName
  }
  Blocks: {
    /** Nothing (a dot), or an icon. The small avatar hides an icon. */
    default: []
  }
  Element: HTMLElement
}

const Image: TOC<{
  Args: AvatarImageSignature['Args'] & { Image: PrimitiveParts['Image'] }
  Element: HTMLImageElement
}> = <template>
  <@Image
    @src={{@src}}
    @crossOrigin={{@crossOrigin}}
    @referrerPolicy={{@referrerPolicy}}
    @onLoadingStatusChange={{@onLoadingStatusChange}}
    class="jn-avatar-image"
    data-slot="avatar-image"
    ...attributes
  />
</template>

const Fallback: TOC<{
  Args: AvatarFallbackSignature['Args'] & { Fallback: PrimitiveParts['Fallback'] }
  Blocks: { default: [] }
  Element: HTMLElement
}> = <template>
  <@Fallback
    @delayMs={{@delayMs}}
    @as={{@as}}
    class="jn-avatar-fallback"
    data-slot="avatar-fallback"
    ...attributes
  >{{yield}}</@Fallback>
</template>

const BADGE = { class: 'jn-avatar-badge', slot: 'avatar-badge', part: 'badge' } as const

/** A badge on the avatar's bottom inline-end corner: a dot, or an icon in one. Upstream's is a `span`. */
const Badge: TOC<AvatarBadgeSignature> = <template>
  <As
    @as={{@as}}
    @tag="span"
    class={{BADGE.class}}
    data-slot={{BADGE.slot}}
    data-test-jn-part={{BADGE.part}}
    ...attributes
  >{{yield}}</As>
</template>

const badge = staticPartModifier(BADGE)

/** What an avatar yields: its parts, and where its image is. */
export interface AvatarParts {
  /** The image: an `<img>`, once it has loaded. Give it `@src` and `alt`. */
  Image: ComponentLike<AvatarImageSignature>
  /** Initials or an icon, shown until the image loads, and if it fails. */
  Fallback: ComponentLike<AvatarFallbackSignature>
  /** A status dot, or an icon, on the bottom inline-end corner. */
  Badge: ComponentLike<AvatarBadgeSignature>
  /** `<span {{a.badge}}>`: makes your own element the badge. */
  badge: PartModifier<HTMLElement>
  /** Where the image is: `idle`, `loading`, `loaded` or `error`. */
  status: ImageLoadingStatus
  /** Whether the image is loading. */
  isLoading: boolean
  /** Whether the image has loaded, and shows. */
  isLoaded: boolean
  /** Whether the image failed to load. */
  isError: boolean
}

export interface AvatarSignature {
  Args: {
    /** Default `default`: 32px. `sm` is 24px, `lg` 40px (in Nova). */
    size?: AvatarSize
    /**
     * The image's URL, ember-primitives' way: the image then needs no `@src` of its own.
     * Upstream's way, `<a.Image @src="…">`, works the same.
     */
    src?: string
    /** The tag to render instead of `span`. */
    as?: TagName
    /** The avatar's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [AvatarParts]
  }
  Element: HTMLElement
}

function sizeOf(size: AvatarSize | undefined): AvatarSize {
  return size ?? 'default'
}

/**
 * An image element with a fallback for representing the user: shadcn's Avatar, on the
 * primitives' `Avatar`. The image renders once it has loaded; until then, and if it fails, the
 * fallback shows.
 *
 *   <Avatar as |a|>
 *     <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
 *     <a.Fallback>CN</a.Fallback>
 *     <a.Badge class="bg-green-600" />
 *   </Avatar>
 *
 * Tests wait for the image: `settled()` resolves once it has loaded or failed.
 */
const Avatar: TOC<AvatarSignature> = <template>
  <AvatarPrimitive
    @src={{@src}}
    @as={{@as}}
    @name={{@name}}
    class="jn-avatar group/avatar"
    data-slot="avatar"
    data-size={{sizeOf @size}}
    ...attributes
    as |p|
  >{{yield
      (hash
        Image=(component Image Image=p.Image)
        Fallback=(component Fallback Fallback=p.Fallback)
        Badge=Badge
        badge=badge
        status=p.status
        isLoading=p.isLoading
        isLoaded=p.isLoaded
        isError=p.isError
      )
    }}</AvatarPrimitive>
</template>

export default Avatar

const COUNT = {
  class: 'jn-avatar-group-count',
  slot: 'avatar-group-count',
  part: 'count',
} as const

/** What an avatar group yields: the count, as a component and as a modifier. */
export interface AvatarGroupParts {
  /** How many more there are (`+3`), or an icon, after the avatars. */
  Count: ComponentLike<StaticPartSignature>
  /** `<button {{g.count}}>`: makes your own element the count. */
  count: PartModifier<HTMLElement>
}

const GROUP_PARTS: AvatarGroupParts = {
  Count: staticPart(COUNT),
  count: staticPartModifier(COUNT),
}

export interface AvatarGroupSignature {
  Args: {
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The group's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The avatars, and the count. */
    default: [AvatarGroupParts]
  }
  Element: HTMLElement
}

/**
 * Avatars in a row, each overlapping the one before, ringed in the background colour; a count
 * at the end says how many more there are. Its avatars' size sets the count's.
 *
 *   <AvatarGroup as |g|>
 *     <Avatar as |a|>…</Avatar>
 *     <Avatar as |a|>…</Avatar>
 *     <g.Count>+3</g.Count>
 *   </AvatarGroup>
 */
export const AvatarGroup: TOC<AvatarGroupSignature> = <template>
  <As
    @as={{@as}}
    class="jn-avatar-group group/avatar-group"
    data-slot="avatar-group"
    data-test-jn="avatar-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield GROUP_PARTS}}</As>
</template>
