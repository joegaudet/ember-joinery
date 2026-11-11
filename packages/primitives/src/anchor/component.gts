import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { modifier } from 'ember-modifier'
import type { ModifierLike } from '@glint/template'
import { anchor } from './position.ts'
import type { AnchorData, AnchorOptions } from './options.ts'

export interface FloatingUISignature {
  /** Everything `anchorTo` takes, but `setData`: the component yields the data instead. */
  Args: Omit<AnchorOptions, 'setData'>
  Blocks: {
    default: [
      /** Put it on the reference: the element the floating one is anchored to. */
      reference: ModifierLike<{ Element: HTMLElement | SVGElement }>,
      /**
       * Put it on the floating element. It is `undefined` until the reference has rendered,
       * so guard it with `{{#if floating}}` where that matters.
       */
      floating: ModifierLike<{ Element: HTMLElement }> | undefined,
      util: {
        /**
         * Sets the reference yourself, for a reference that already has a modifier of its own:
         * call it from that modifier instead of adding `reference`.
         */
        setReference: (element: HTMLElement | SVGElement) => void
        /** Where the floating element went: placement, position and middleware data. */
        data: AnchorData | undefined
      },
    ]
  }
}

/**
 * ember-primitives' `<FloatingUI>`: no element of its own, it yields a modifier for the
 * reference and one for the floating element, anchored to it as `anchorTo` does.
 *
 *   <FloatingUI @placement="bottom-start" @offsetOptions={{8}} as |reference floating util|>
 *     <button type="button" {{reference}}>More</button>
 *     <div {{floating}} data-side={{util.data.placement}}>…</div>
 *   </FloatingUI>
 */
export class FloatingUI extends Component<FloatingUISignature> {
  @tracked referenceElement: HTMLElement | SVGElement | undefined
  @tracked data: AnchorData | undefined

  setReference = (element: HTMLElement | SVGElement): void => {
    this.referenceElement = element
  }

  /** The reference's modifier. */
  reference = modifier<{ Element: HTMLElement | SVGElement }>(element => {
    this.setReference(element)
  })

  setData = (data: AnchorData): void => {
    this.data = data
  }

  /** The floating element's modifier: positions it again whenever an argument changes. */
  floating = modifier<{ Element: HTMLElement }>(element => {
    const { referenceElement: reference, args } = this
    if (!reference) return
    return anchor(element, reference, {
      placement: args.placement,
      side: args.side,
      align: args.align,
      sideOffset: args.sideOffset,
      alignOffset: args.alignOffset,
      offsetOptions: args.offsetOptions,
      strategy: args.strategy,
      avoidCollisions: args.avoidCollisions,
      collisionPadding: args.collisionPadding,
      flipOptions: args.flipOptions,
      shiftOptions: args.shiftOptions,
      sticky: args.sticky,
      hideWhenDetached: args.hideWhenDetached,
      hideOptions: args.hideOptions,
      arrow: args.arrow,
      arrowPadding: args.arrowPadding,
      middleware: args.middleware,
      setData: this.setData,
    })
  })

  <template>
    {{yield
      this.reference
      (if this.referenceElement this.floating)
      (hash setReference=this.setReference data=this.data)
    }}
  </template>
}
