// `@ember-joinery/primitives/scroll-area`: a scrollable area with scrollbars of its own drawing,
// as Radix's ScrollArea (which shadcn's Scroll Area wraps). The files beside this index are
// private to the feature.
export {
  ScrollArea,
  ScrollAreaCorner,
  ScrollAreaScrollbar,
  ScrollAreaThumb,
  ScrollAreaViewport,
  type ScrollAreaCornerSignature,
  type ScrollAreaScrollbarSignature,
  type ScrollAreaSignature,
  type ScrollAreaThumbSignature,
  type ScrollAreaViewportSignature,
  type ScrollAreaYield,
} from './components.gts'
export {
  ScrollAreaState,
  ScrollbarPart,
  ScrollbarState,
  scrollFromPointer,
  thumbOffset,
  thumbRatio,
  thumbSize,
  type ScrollAreaOptions,
  type ScrollAreaOrientation,
  type ScrollAreaPartModifier,
  type ScrollAreaType,
  type ScrollbarSizes,
} from './state.ts'
