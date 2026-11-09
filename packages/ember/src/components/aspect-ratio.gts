import type { TOC } from '@ember/component/template-only'
import { AspectRatio as AspectRatioPrimitive } from '@ember-joinery/primitives/aspect-ratio'
import type { TagName } from '@ember-joinery/primitives/as'

export interface AspectRatioSignature {
  Args: {
    /** Width over height, as a number: `16 / 9` for widescreen, `1` for a square. Default 1. */
    ratio?: number
    /** The inner element's tag. Default `div`. */
    as?: TagName
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** What takes the ratio: an image, a video, a map. Give it `width` and `height` of 100%. */
    default: []
  }
  /** The inner element, which fills the box. */
  Element: HTMLDivElement
}

/**
 * Displays content within a desired ratio: shadcn's AspectRatio, on the primitives'
 * `AspectRatio`. Upstream's adds only `data-slot`; Joinery's adds the `jn-aspect-ratio` class
 * too, as every part has one, and no rule styles it. Attributes go on the inner box.
 *
 *   const widescreen = 16 / 9
 *
 *   <AspectRatio @ratio={{widescreen}} class="rounded-lg bg-muted">
 *     <img src="…" alt="Photo" class="size-full rounded-lg object-cover" />
 *   </AspectRatio>
 */
const AspectRatio: TOC<AspectRatioSignature> = <template>
  <AspectRatioPrimitive
    @ratio={{@ratio}}
    @as={{@as}}
    @name={{@name}}
    class="jn-aspect-ratio"
    data-slot="aspect-ratio"
    ...attributes
  >{{yield}}</AspectRatioPrimitive>
</template>

export default AspectRatio
