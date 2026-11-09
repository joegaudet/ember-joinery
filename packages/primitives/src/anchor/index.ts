// `@ember-joinery/primitives/anchor`: positioning one element against another, with CSS anchor
// positioning where the browser has it and Floating UI otherwise. The files beside this index
// are private to the feature.
export { anchor, ANCHOR_PROPERTIES } from './position.ts'
export { anchorTo, type AnchorToSignature } from './modifier.ts'
export { FloatingUI, type FloatingUISignature } from './component.gts'
export {
  exposeMetadata,
  flipTo,
  originFor,
  transformOrigin,
  type AnchorFlipOptions,
  type ArrowSize,
} from './middleware.ts'
export {
  anchorMode,
  isAnchorFallbackForced,
  supportsAnchorPositioning,
  type Align,
  type AnchorData,
  type AnchorMode,
  type AnchorOptions,
  type AnchorReference,
  type Side,
} from './options.ts'
// Floating UI's types that the options above take, so callers needn't depend on it themselves.
export type {
  HideOptions,
  Middleware,
  MiddlewareState,
  OffsetOptions,
  Padding,
  Placement,
  ShiftOptions,
  Strategy,
  VirtualElement,
} from '@floating-ui/dom'
