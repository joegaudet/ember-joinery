import Component from '@glimmer/component'
import { rectanglePath } from '../-private/paths.ts'
import type { RectangleProps } from '../-private/parts.gts'

export interface RectangleSignature {
  Args: {
    /**
     * A bar's `@shape` props, as recharts' `{...props}`: the bar's rectangle and attributes.
     * The arguments below override them.
     */
    props?: Partial<RectangleProps>
    x?: number
    y?: number
    width?: number
    height?: number
    /** The corners' radius: one for all four, or `[topLeft, topRight, bottomRight, bottomLeft]`. */
    radius?: number | readonly number[]
  }
  Element: Element
}

/**
 * A rectangle with rounded corners: recharts' `Rectangle`. A bar draws each of its bars with
 * one; draw one yourself in a bar's `@shape`, given the props it is handed, with attributes of
 * your own (they win over the bar's):
 *
 *   const DashedBar = <template>
 *     <Rectangle @props={{@props}} stroke={{@props.payload.fill}} stroke-dasharray="4" />
 *   </template>
 */
export default class Rectangle extends Component<RectangleSignature> {
  get d(): string {
    const props = this.args.props ?? {}
    return rectanglePath(
      this.args.x ?? props.x ?? 0,
      this.args.y ?? props.y ?? 0,
      this.args.width ?? props.width ?? 0,
      this.args.height ?? props.height ?? 0,
      this.args.radius ?? props.radius ?? 0,
    )
  }

  get value(): string | undefined {
    const value = this.args.props?.value
    return value === undefined || value === null ? undefined : String(value)
  }

  <template>
    <path
      class="recharts-rectangle"
      fill={{@props.fill}}
      fill-opacity={{@props.fillOpacity}}
      stroke={{@props.stroke}}
      stroke-width={{@props.strokeWidth}}
      d={{this.d}}
      data-test-jn-part="bar"
      data-test-jn-value={{this.value}}
      ...attributes
    ></path>
  </template>
}
