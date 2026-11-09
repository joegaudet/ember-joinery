import Component from '@glimmer/component'
import { htmlSafe, type SafeString } from '@ember/template'
import type { ComponentLike } from '@glint/template'
import Icon, { type IconNode } from '@ember-joinery/ember/components/icon'
import { cssValue, payloadConfig } from '../-private/config.ts'
import type { ChartConfig, LegendPayloadItem } from '../types.ts'

export interface ChartLegendContentSignature {
  Args: {
    /** The legend's entries; the chart passes them. */
    payload?: readonly LegendPayloadItem[]
    /** Where the legend sits; the chart passes it. `top` puts the space below it. */
    verticalAlign?: 'top' | 'middle' | 'bottom'
    /** The chart's config; the chart passes the container's. */
    config?: ChartConfig
    /** Shows a swatch even where the config has an icon. */
    hideIcon?: boolean
    /** The config or row key to name the entries by. Default each entry's data key. */
    nameKey?: string
    /** Classes for the legend, for use in a curried `@content`. */
    class?: string
  }
  Element: HTMLDivElement
}

interface Entry {
  key: string
  label: string
  iconNode?: IconNode
  iconComponent?: ComponentLike<{ Element: Element }>
  swatchStyle: SafeString
}

/**
 * A chart legend: each series' colour (or its config icon) and its config label, in a centred
 * row. shadcn's `ChartLegendContent`; give it to a chart's legend as its content:
 *
 *   <c.ChartLegend @content={{component ChartLegendContent nameKey="browser"}} />
 */
export default class ChartLegendContent extends Component<ChartLegendContentSignature> {
  get entries(): Entry[] {
    const { payload, nameKey, hideIcon } = this.args
    const config = this.args.config ?? {}
    return (payload ?? [])
      .filter(item => item.type !== 'none')
      .map(item => {
        const key = `${nameKey ?? (typeof item.dataKey === 'function' ? undefined : item.dataKey) ?? 'value'}`
        const itemConfig = payloadConfig(config, item, key)
        const icon = hideIcon ? undefined : itemConfig?.icon
        const color = cssValue(item.color)
        return {
          key,
          label: itemConfig?.label ?? '',
          iconNode: Array.isArray(icon) ? (icon as IconNode) : undefined,
          iconComponent:
            icon && !Array.isArray(icon)
              ? (icon as ComponentLike<{ Element: Element }>)
              : undefined,
          swatchStyle: htmlSafe(color ? `background-color: ${color};` : ''),
        }
      })
  }

  <template>
    {{#if @payload.length}}
      {{! A data-slot upstream's legend doesn't have, as the tooltip's: see ChartTooltipContent. }}
      <div
        class="jn-chart-legend {{@class}}"
        data-slot="chart-legend"
        data-vertical-align={{if @verticalAlign @verticalAlign "bottom"}}
        data-test-jn="chart-legend"
        ...attributes
      >
        {{#each this.entries as |entry|}}
          <div
            class="jn-chart-legend-item"
            data-test-jn-part="item"
            data-test-jn-value={{entry.key}}
          >
            {{#if entry.iconNode}}
              <Icon @icon={{entry.iconNode}} />
            {{else if entry.iconComponent}}
              <entry.iconComponent />
            {{else}}
              <div
                class="jn-chart-legend-swatch"
                style={{entry.swatchStyle}}
                data-test-jn-part="swatch"
              ></div>
            {{/if}}
            {{entry.label}}
          </div>
        {{/each}}
      </div>
    {{/if}}
  </template>
}
