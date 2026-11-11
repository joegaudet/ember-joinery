// shadcn's `components/ui/direction`: the text direction for everything inside a provider, and
// how a component reads it. Joinery's provider is the primitive's, so the two packages give the
// same one. Its page in the guide is Direction, under Components.
export {
  DirectionProvider,
  getDirection,
  isRTL,
  type Direction,
  type DirectionProviderSignature,
} from '@ember-joinery/primitives/direction'
