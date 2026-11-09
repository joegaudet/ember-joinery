import type { TOC } from '@ember/component/template-only'
import type { TagName } from '@ember-joinery/primitives/as'
import type { Direction } from '@ember-joinery/primitives/direction'
import {
  ScrollArea as PrimitiveScrollArea,
  ScrollAreaCorner,
  ScrollAreaScrollbar,
  ScrollAreaThumb,
  ScrollAreaViewport,
  type ScrollAreaOrientation,
  type ScrollAreaType,
} from '@ember-joinery/primitives/scroll-area'

export interface ScrollBarSignature {
  Args: {
    /** `vertical` (the default) or `horizontal`. */
    orientation?: ScrollAreaOrientation
    /** Keep it rendered while it is hidden, for hiding it in CSS of your own. */
    forceMount?: boolean
  }
  Element: HTMLElement
}

/**
 * A scrollbar of a `<ScrollArea>`, with its thumb, as shadcn's `ScrollBar`. The area draws a
 * vertical one itself; put `<ScrollBar @orientation="horizontal" />` inside it for the other
 * way. It finds its area wherever it is inside it.
 */
export const ScrollBar: TOC<ScrollBarSignature> = <template>
  <ScrollAreaScrollbar
    @orientation={{@orientation}}
    @forceMount={{@forceMount}}
    class="jn-scroll-area-scrollbar"
    data-slot="scroll-area-scrollbar"
    ...attributes
  >
    <ScrollAreaThumb class="jn-scroll-area-thumb" data-slot="scroll-area-thumb" />
  </ScrollAreaScrollbar>
</template>

export interface ScrollAreaSignature {
  Args: {
    /**
     * When the scrollbars show: while the pointer is over the area (`hover`, the default), while
     * it scrolls (`scroll`), whenever the content overflows (`auto`), or `always`.
     */
    type?: ScrollAreaType
    /** How long a scrollbar stays once the pointer leaves or the scrolling stops, in ms. Default 600. */
    scrollHideDelay?: number
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `ScrollAreaHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The content, which scrolls; a `<ScrollBar @orientation="horizontal" />` can go in it. */
    default: []
  }
  Element: HTMLElement
}

/**
 * Augments native scroll functionality for custom, cross-browser styling: shadcn's Scroll Area,
 * on Joinery's `ScrollArea` primitive (Radix's). Its content scrolls natively; its scrollbar is
 * drawn by the style, and shows while the pointer is over it (`@type`).
 *
 *   <ScrollArea class="h-[200px] w-[350px] rounded-md border p-4">
 *     Your scrollable content here.
 *   </ScrollArea>
 */
export const ScrollArea: TOC<ScrollAreaSignature> = <template>
  <PrimitiveScrollArea
    @type={{@type}}
    @scrollHideDelay={{@scrollHideDelay}}
    @dir={{@dir}}
    @as={{@as}}
    @name={{@name}}
    class="jn-scroll-area"
    data-slot="scroll-area"
    ...attributes
  >
    <ScrollAreaViewport class="jn-scroll-area-viewport" data-slot="scroll-area-viewport">
      {{yield}}
    </ScrollAreaViewport>
    <ScrollBar />
    <ScrollAreaCorner />
  </PrimitiveScrollArea>
</template>
