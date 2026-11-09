import Component from '@glimmer/component'
import { THEMES, type ChartConfig } from '../types.ts'
import { cssValue } from '../-private/config.ts'

export interface ChartStyleSignature {
  Args: {
    /** The chart's id, as its `data-chart` attribute holds it. */
    id: string
    config: ChartConfig
  }
}

/**
 * The `<style>` that gives a chart its colours: `--color-<key>` for each config entry with a
 * `color` (or a `theme`, with its dark colour under `.dark`), scoped to `[data-chart=<id>]`.
 * `ChartContainer` renders it; render it yourself only for a chart outside one. shadcn's
 * `ChartStyle`.
 */
export default class ChartStyle extends Component<ChartStyleSignature> {
  get css(): string | null {
    const entries = Object.entries(this.args.config ?? {}).filter(
      ([, item]) => item.theme ?? item.color,
    )
    if (!entries.length) return null
    const id = this.args.id
    return Object.entries(THEMES)
      .map(
        ([theme, prefix]) => `
${prefix} [data-chart=${id}] {
${entries
  .map(([key, item]) => {
    const color = cssValue(item.theme?.[theme as keyof typeof THEMES] ?? item.color)
    return color ? `  --color-${key}: ${color};` : null
  })
  .filter(Boolean)
  .join('\n')}
}
`,
      )
      .join('\n')
  }

  <template>
    {{#if this.css}}
      <style>{{this.css}}</style>
    {{/if}}
  </template>
}
