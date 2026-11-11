import type { TOC } from '@ember/component/template-only'

export interface DotSignature {
  Args: {
    /** The centre. */
    cx: number
    cy: number
    /** The radius. */
    r: number
  }
  Element: Element
}

/**
 * A circle at a point: recharts' `Dot`, for a series' custom `@dot`. Give it `fill`, `stroke`
 * and any other attribute:
 *
 *   const ColoredDot = <template>
 *     <Dot @cx={{@cx}} @cy={{@cy}} @r={{5}} fill={{@payload.fill}} stroke={{@payload.fill}} />
 *   </template>
 */
const Dot: TOC<DotSignature> = <template>
  <circle class="recharts-dot" cx={{@cx}} cy={{@cy}} r={{@r}} ...attributes></circle>
</template>

export default Dot
