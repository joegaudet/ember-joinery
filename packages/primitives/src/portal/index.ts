// `@ember-joinery/primitives/portal`: rendering content elsewhere in the document, with
// ember-primitives' `Portal`, `PortalTargets` and `PortalTarget`. The files beside this index
// are private to the feature.
export { Portal, wormhole, type PortalSignature } from './portal.gts'
export {
  PORTALS,
  PortalTarget,
  PortalTargets,
  findNearestTarget,
  type PortalName,
  type PortalTargetSignature,
  type PortalTargetsSignature,
} from './targets.gts'
