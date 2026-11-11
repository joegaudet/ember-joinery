import { modifier } from 'ember-modifier'
import { anchor } from './position.ts'
import type { AnchorOptions, AnchorReference } from './options.ts'

export interface AnchorToSignature {
  Element: HTMLElement
  Args: {
    Positional: [
      /**
       * What to anchor to: an element, a selector (`"#trigger"`), or a Floating UI virtual
       * element. Nothing (`null` or `undefined`) leaves the element where it is, for a
       * reference that hasn't rendered yet.
       */
      reference: AnchorReference | null | undefined,
    ]
    Named: AnchorOptions
  }
}

/**
 * Anchors the element it is on to another, as ember-primitives' `anchorTo` does, with CSS
 * anchor positioning where the browser has it and Floating UI otherwise (see `anchor`). It
 * takes ember-primitives' arguments (`placement`, `offsetOptions`, `flipOptions`…) and
 * Radix's (`side`, `align`, `sideOffset`, `arrow`…):
 *
 *   <button id="trigger">…</button>
 *   <div {{anchorTo "#trigger" side="bottom" align="start" sideOffset=4}}>…</div>
 *
 * When an argument changes, it positions the element again from scratch.
 */
export const anchorTo = modifier<AnchorToSignature>((floating, [reference], options) => {
  if (!reference) return
  return anchor(floating, reference, options)
})
