/*
 * Reading a chart's config, as shadcn's chart.tsx reads it.
 */
import type { ChartConfig, ChartConfigItem } from '../types.ts'

/**
 * shadcn's `getPayloadConfigFromPayload`: the config entry for a tooltip or legend item. The
 * entry is found by `key`, or by the string at `key` in the item or in its row (so
 * `nameKey="browser"` finds `chrome` in `{ browser: 'chrome' }`).
 */
export function payloadConfig(
  config: ChartConfig | undefined,
  payload: unknown,
  key: string,
): ChartConfigItem | undefined {
  if (!config || typeof payload !== 'object' || payload === null) return undefined
  const item = payload as Record<string, unknown>
  const row =
    'payload' in item && typeof item['payload'] === 'object' && item['payload'] !== null
      ? (item['payload'] as Record<string, unknown>)
      : undefined
  let configLabelKey = key
  if (key in item && typeof item[key] === 'string') {
    configLabelKey = item[key]
  } else if (row && key in row && typeof row[key] === 'string') {
    configLabelKey = row[key]
  }
  return configLabelKey in config ? config[configLabelKey] : config[key]
}

/**
 * A colour safe to write into a `style` attribute or a style sheet: one value, with nothing
 * that could end the declaration or the rule.
 */
export function cssValue(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined
  const text = String(value)
  return /[;{}<>"\\]/.test(text) ? undefined : text
}
