import Component from '@glimmer/component'

/**
 * One element of an icon's drawing: a tag (`path`, `circle`…) and its attributes, as in a
 * `lucide` icon.
 */
export type IconElement = readonly [
  tag: string,
  attributes: Readonly<Record<string, string | number>>,
]

/**
 * An icon, as the `lucide` package exports each one: `['svg', attributes, elements]`, or just
 * its elements (the form later `lucide` versions use).
 */
export type IconNode =
  | readonly [
      tag: string,
      attributes: Readonly<Record<string, string | number>>,
      elements?: readonly IconElement[],
    ]
  | readonly IconElement[]

export interface IconSignature {
  Args: {
    /** The icon: import it from `lucide` (`import { ArrowUp } from 'lucide'`), one per icon. */
    icon: IconNode
    /** Its width and height. Default 24, as lucide's; a component's CSS usually sets it. */
    size?: number | string
    /** The stroke colour. Default `currentColor`. */
    color?: string
    /** The stroke width, in the icon's 24-unit grid. Default 2. */
    strokeWidth?: number | string
    /** Keeps the stroke `strokeWidth` pixels wide whatever the icon's size, as lucide's prop. */
    absoluteStrokeWidth?: boolean
    /**
     * What the icon means, for an icon that stands alone. With it, the icon is an image with
     * that name; without it (the usual case, next to text or inside a labelled button), it is
     * hidden from assistive technology.
     */
    label?: string
    /** The icon's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Element: SVGSVGElement
}

function elementsOf(icon: IconNode): readonly IconElement[] {
  // lucide 0.x: ['svg', defaultAttributes, elements]. Later: the elements alone.
  if (typeof icon[0] === 'string')
    return ((icon as readonly unknown[])[2] as readonly IconElement[]) ?? []
  return icon as readonly IconElement[]
}

/**
 * A `lucide` icon, drawn as lucide's own components draw it: a 24×24 `<svg>` with a round
 * `currentColor` stroke and the class `lucide`. Import each icon you use from the `lucide`
 * package, so a build keeps only those:
 *
 *   import { ArrowUp } from 'lucide'
 *
 *   <Icon @icon={{ArrowUp}} />
 *   <Icon @icon={{ArrowUp}} @label="Back to top" />   {{! an icon that stands alone }}
 *
 * It draws the elements and attributes lucide's icons use: `path`, `circle`, `rect`, `line`,
 * `polyline`, `polygon` and `ellipse`, with their geometry and `fill`. Components that show an
 * icon of their own take a replacement for it, so any icon set works.
 */
export default class Icon extends Component<IconSignature> {
  get elements(): readonly IconElement[] {
    return elementsOf(this.args.icon)
  }

  get size(): string {
    return String(this.args.size ?? 24)
  }

  get strokeWidth(): string {
    const width = Number(this.args.strokeWidth ?? 2)
    if (!this.args.absoluteStrokeWidth) return String(width)
    return String((width * 24) / Number(this.args.size ?? 24))
  }

  is = (element: IconElement, tag: string): boolean => element[0] === tag
  attr = (element: IconElement, name: string): string | undefined => {
    const value = element[1][name]
    return value === undefined ? undefined : String(value)
  }

  <template>
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={{this.size}}
      height={{this.size}}
      viewBox="0 0 24 24"
      fill="none"
      stroke={{if @color @color "currentColor"}}
      stroke-width={{this.strokeWidth}}
      stroke-linecap="round"
      stroke-linejoin="round"
      class="lucide"
      role={{if @label "img"}}
      aria-label={{@label}}
      aria-hidden={{if @label undefined "true"}}
      data-test-jn="icon"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{#each this.elements as |element|}}
        {{#if (this.is element "path")}}
          <path d={{this.attr element "d"}} fill={{this.attr element "fill"}} />
        {{else if (this.is element "circle")}}
          <circle
            cx={{this.attr element "cx"}}
            cy={{this.attr element "cy"}}
            r={{this.attr element "r"}}
            fill={{this.attr element "fill"}}
          />
        {{else if (this.is element "rect")}}
          <rect
            x={{this.attr element "x"}}
            y={{this.attr element "y"}}
            width={{this.attr element "width"}}
            height={{this.attr element "height"}}
            rx={{this.attr element "rx"}}
            ry={{this.attr element "ry"}}
            fill={{this.attr element "fill"}}
          />
        {{else if (this.is element "line")}}
          <line
            x1={{this.attr element "x1"}}
            y1={{this.attr element "y1"}}
            x2={{this.attr element "x2"}}
            y2={{this.attr element "y2"}}
          />
        {{else if (this.is element "polyline")}}
          <polyline points={{this.attr element "points"}} />
        {{else if (this.is element "polygon")}}
          <polygon points={{this.attr element "points"}} fill={{this.attr element "fill"}} />
        {{else if (this.is element "ellipse")}}
          <ellipse
            cx={{this.attr element "cx"}}
            cy={{this.attr element "cy"}}
            rx={{this.attr element "rx"}}
            ry={{this.attr element "ry"}}
            fill={{this.attr element "fill"}}
          />
        {{/if}}
      {{/each}}
    </svg>
  </template>
}
