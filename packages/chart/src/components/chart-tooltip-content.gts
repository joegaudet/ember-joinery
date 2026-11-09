import Component from '@glimmer/component'
import { getComponentTemplate } from '@ember/component'
import { htmlSafe, type SafeString } from '@ember/template'
import type { ComponentLike } from '@glint/template'
import Icon, { type IconNode } from '@ember-joinery/ember/components/icon'
import { cssValue, payloadConfig } from '../-private/config.ts'
import type {
  ChartConfig,
  ChartIcon,
  ChartTooltipContentArgs,
  LabelFormatter,
  TooltipFormatter,
  TooltipFormatterSignature,
  TooltipPayloadItem,
  ValueFormatter,
} from '../types.ts'

/** How a tooltip marks each series: a square `dot`, a `line`, or a `dashed` line. */
export type ChartTooltipIndicator = 'dot' | 'line' | 'dashed'

export interface ChartTooltipContentSignature {
  Args: {
    /** Whether the tooltip is showing; the chart passes it. */
    active?: boolean
    /** The entries at the active row; the chart passes them. */
    payload?: readonly TooltipPayloadItem[]
    /** The active row's category; the chart passes it. */
    label?: unknown
    /** The chart's config; the chart passes the container's. */
    config?: ChartConfig
    /** Where the tooltip points; the chart passes it. Unused. */
    coordinate?: { x: number; y: number }
    /** The chart tooltip's own label class and formatters; the chart passes them. */
    tooltip?: ChartTooltipContentArgs['tooltip']
    /** Hides the label. */
    hideLabel?: boolean
    /** Hides each entry's indicator. */
    hideIndicator?: boolean
    /** `dot` (default), `line` or `dashed`. */
    indicator?: ChartTooltipIndicator
    /** The config or row key to name the entries by. Default each entry's name. */
    nameKey?: string
    /** The config or data key to label the tooltip by. Default the active row's category. */
    labelKey?: string
    /** Formats the label. */
    labelFormatter?: LabelFormatter
    /** Classes for the label. */
    labelClassName?: string
    /**
     * Formats each entry, in place of its indicator, name and value: a function returning its
     * text, or a component that draws it (for markup, as recharts' formatter can return).
     */
    formatter?: TooltipFormatter
    /** One indicator colour for every entry. Default each entry's `fill` (in its row) or colour. */
    color?: string
    /** Classes for the tooltip box, for use in a curried `@content`: `class="w-[150px]"`. */
    class?: string
  }
  Element: HTMLDivElement
}

interface Entry {
  key: string
  name: string
  value: string | null
  icon?: ChartIcon
  iconNode?: IconNode
  iconComponent?: ComponentLike<{ Element: Element }>
  indicatorStyle: SafeString
  /** The formatter function's text. */
  formatted?: string
  /** What the formatter component is handed. */
  custom?: Omit<TooltipFormatterSignature['Args'], 'config'>
}

function text(value: unknown): string {
  return typeof value === 'number' ? value.toLocaleString() : String(value)
}

/**
 * Whether a formatter is a component rather than a function: a `<template>` or a curried
 * `(component …)` is not a function at all, and a class component has a template.
 */
function isFormatterComponent(
  formatter: TooltipFormatter,
): formatter is ComponentLike<TooltipFormatterSignature> {
  return (
    typeof formatter !== 'function' ||
    getComponentTemplate(formatter) !== undefined ||
    /^class[\s{]/.test(Function.prototype.toString.call(formatter))
  )
}

/**
 * A chart tooltip's box: the active row's label, then each series with its colour, name and
 * value. shadcn's `ChartTooltipContent`; give it to a chart's tooltip as its content, with any
 * of its arguments curried in:
 *
 *   <c.ChartTooltip @content={{component ChartTooltipContent indicator="line"}} />
 *
 * It draws nothing while the tooltip is inactive or empty. It also renders on its own, given
 * `@active`, `@payload` and `@label`.
 */
export default class ChartTooltipContent extends Component<ChartTooltipContentSignature> {
  get indicator(): ChartTooltipIndicator {
    return this.args.indicator ?? 'dot'
  }

  get visible(): boolean {
    return Boolean(this.args.active && this.args.payload?.length)
  }

  get labelFormatter(): LabelFormatter | undefined {
    return this.args.tooltip?.labelFormatter ?? this.args.labelFormatter
  }

  get labelClassName(): string | undefined {
    return this.args.tooltip?.labelClassName ?? this.args.labelClassName
  }

  get formatter(): TooltipFormatter | undefined {
    return this.args.tooltip?.formatter ?? this.args.formatter
  }

  /** The formatter, when it is a component. */
  get formatterComponent(): ComponentLike<TooltipFormatterSignature> | undefined {
    const formatter = this.formatter
    return formatter && isFormatterComponent(formatter) ? formatter : undefined
  }

  get config(): ChartConfig {
    return this.args.config ?? {}
  }

  get nestLabel(): boolean {
    return (this.args.payload?.length ?? 0) === 1 && this.indicator !== 'dot'
  }

  /** The label's text, or null for none. */
  get label(): { text: string } | null {
    const { hideLabel, payload, labelKey, label } = this.args
    const labelFormatter = this.labelFormatter
    const config = this.args.config ?? {}
    if (hideLabel || !payload?.length) return null
    const [item] = payload
    const key = `${labelKey ?? (typeof item?.dataKey === 'function' ? undefined : item?.dataKey) ?? item?.name ?? 'value'}`
    const itemConfig = payloadConfig(config, item, key)
    const value =
      !labelKey && typeof label === 'string' ? (config[label]?.label ?? label) : itemConfig?.label
    if (labelFormatter) return { text: String(labelFormatter(value, payload) ?? '') }
    if (!value) return null
    return { text: String(value) }
  }

  get entries(): Entry[] {
    const { payload, nameKey, color } = this.args
    const formatter = this.formatter
    const config = this.args.config ?? {}
    return (payload ?? [])
      .filter(item => item.type !== 'none')
      .map((item, index) => {
        const key = `${nameKey ?? item.name ?? (typeof item.dataKey === 'function' ? undefined : item.dataKey) ?? 'value'}`
        const itemConfig = payloadConfig(config, item, key)
        const indicatorColor = cssValue(color ?? item.payload?.['fill'] ?? item.color)
        const icon = itemConfig?.icon
        const entry: Entry = {
          key,
          name: String(itemConfig?.label ?? item.name ?? ''),
          value: item.value !== null && item.value !== undefined ? text(item.value) : null,
          icon,
          iconNode: Array.isArray(icon) ? (icon as IconNode) : undefined,
          iconComponent:
            icon && !Array.isArray(icon)
              ? (icon as ComponentLike<{ Element: Element }>)
              : undefined,
          indicatorStyle: htmlSafe(
            indicatorColor
              ? `--color-bg: ${indicatorColor}; --color-border: ${indicatorColor};`
              : '',
          ),
        }
        if (formatter && item.value !== undefined && item.name) {
          if (isFormatterComponent(formatter)) {
            entry.custom = {
              value: item.value as number | string,
              name: item.name,
              item,
              index,
              payload: item.payload,
            }
          } else {
            entry.formatted = String(
              (formatter as ValueFormatter)(item.value, item.name, item, index, item.payload) ?? '',
            )
          }
        }
        return entry
      })
  }

  <template>
    {{#if this.visible}}
      {{! Upstream's box has no data-slot; Joinery's gives it one, so the share of Tailwind's
          preflight Joinery's parts get (border-box sizing) applies outside a chart too. }}
      <div
        class="jn-chart-tooltip {{@class}}"
        data-slot="chart-tooltip"
        data-test-jn="chart-tooltip"
        data-indicator={{this.indicator}}
        ...attributes
      >
        {{#unless this.nestLabel}}
          {{#if this.label}}
            <div class="jn-chart-tooltip-label {{this.labelClassName}}" data-test-jn-part="label">
              {{this.label.text}}
            </div>
          {{/if}}
        {{/unless}}
        <div class="jn-chart-tooltip-items">
          {{#each this.entries as |entry|}}
            <div
              class="jn-chart-tooltip-item"
              data-indicator={{this.indicator}}
              data-test-jn-part="item"
              data-test-jn-value={{entry.key}}
            >
              {{#if entry.custom}}
                {{#if this.formatterComponent}}
                  <this.formatterComponent
                    @value={{entry.custom.value}}
                    @name={{entry.custom.name}}
                    @item={{entry.custom.item}}
                    @index={{entry.custom.index}}
                    @payload={{entry.custom.payload}}
                    @config={{this.config}}
                  />
                {{/if}}
              {{else if entry.formatted}}
                {{entry.formatted}}
              {{else}}
                {{#if entry.iconNode}}
                  <Icon @icon={{entry.iconNode}} />
                {{else if entry.iconComponent}}
                  <entry.iconComponent />
                {{else}}
                  {{#unless @hideIndicator}}
                    <div
                      class="jn-chart-tooltip-indicator"
                      data-indicator={{this.indicator}}
                      data-nested={{if this.nestLabel "true"}}
                      style={{entry.indicatorStyle}}
                      data-test-jn-part="indicator"
                    ></div>
                  {{/unless}}
                {{/if}}
                <div class="jn-chart-tooltip-body" data-nested={{if this.nestLabel "true" "false"}}>
                  <div class="jn-chart-tooltip-names">
                    {{#if this.nestLabel}}
                      {{#if this.label}}
                        <div
                          class="jn-chart-tooltip-label {{this.labelClassName}}"
                          data-test-jn-part="label"
                        >
                          {{this.label.text}}
                        </div>
                      {{/if}}
                    {{/if}}
                    <span
                      class="jn-chart-tooltip-name"
                      data-test-jn-part="name"
                    >{{entry.name}}</span>
                  </div>
                  {{#if entry.value}}
                    <span
                      class="jn-chart-tooltip-value"
                      data-test-jn-part="value"
                    >{{entry.value}}</span>
                  {{/if}}
                </div>
              {{/if}}
            </div>
          {{/each}}
        </div>
      </div>
    {{/if}}
  </template>
}
