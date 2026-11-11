import Component from '@glimmer/component'
import { sectorD } from '../-private/polar.ts'
import type { SectorProps } from '../-private/parts.gts'

export interface SectorSignature {
  Args: {
    /**
     * A pie's `@shape` props, as recharts' `{...props}`: the sector's geometry and attributes.
     * The arguments below override them.
     */
    props?: Partial<SectorProps>
    /** The centre. */
    cx?: number
    cy?: number
    /** The ring: 0 inside for a slice of pie, more for a donut's. */
    innerRadius?: number
    outerRadius?: number
    /** The angles, in degrees counter-clockwise from 3 o'clock. */
    startAngle?: number
    endAngle?: number
    /** Rounds the corners: pixels, or a percentage of the ring's width. */
    cornerRadius?: number | string
  }
  Element: Element
}

/**
 * A pie's sector: recharts' `Sector`. A pie draws each of its sectors with one; draw one
 * yourself in a pie's `@shape`, given the props it is handed, and override any of them:
 *
 *   const ActiveShape = <template>
 *     <Sector @props={{@props}} @outerRadius={{add @props.outerRadius 10}} />
 *   </template>
 *
 * It takes the sector's `fill`, `stroke` and `stroke-width` from `@props`; attributes on it win.
 */
export default class Sector extends Component<SectorSignature> {
  get geometry() {
    const props = this.args.props ?? {}
    return {
      cx: this.args.cx ?? props.cx ?? 0,
      cy: this.args.cy ?? props.cy ?? 0,
      innerRadius: this.args.innerRadius ?? props.innerRadius ?? 0,
      outerRadius: this.args.outerRadius ?? props.outerRadius ?? 0,
      startAngle: this.args.startAngle ?? props.startAngle ?? 0,
      endAngle: this.args.endAngle ?? props.endAngle ?? 0,
      cornerRadius: this.args.cornerRadius ?? props.cornerRadius ?? 0,
    }
  }

  get d(): string | null {
    return sectorD(this.geometry)
  }

  get name(): string | undefined {
    const name = this.args.props?.name
    return name === undefined || name === null ? undefined : String(name)
  }

  <template>
    {{#if this.d}}
      <path
        class="recharts-sector"
        fill={{@props.fill}}
        fill-opacity={{@props.fillOpacity}}
        stroke={{@props.stroke}}
        stroke-width={{@props.strokeWidth}}
        d={{this.d}}
        data-test-jn-part="sector"
        data-test-jn-value={{this.name}}
        ...attributes
      ></path>
    {{/if}}
  </template>
}
