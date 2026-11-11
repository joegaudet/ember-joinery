import type { MaskitoOptions } from '@maskito/core'
import {
  maskitoDate,
  maskitoDateRange,
  maskitoDateTime,
  maskitoNumber,
  maskitoParseDate,
  maskitoParseNumber,
  maskitoParseTime,
  maskitoStringifyDate,
  maskitoStringifyNumber,
  maskitoStringifyTime,
  maskitoTime,
  type MaskitoDateMode,
  type MaskitoDateParams,
  type MaskitoDateRangeParams,
  type MaskitoDateTimeParams,
  type MaskitoNumberParams,
  type MaskitoTimeMode,
  type MaskitoTimeParams,
} from '@maskito/kit'

export type {
  MaskitoDateMode,
  MaskitoDateParams,
  MaskitoDateRangeParams,
  MaskitoDateTimeParams,
  MaskitoNumberParams,
  MaskitoTimeMode,
  MaskitoTimeParams,
}

/** A date preset's parameters: `@maskito/kit`'s, each optional. */
export type DateMaskParams = Partial<MaskitoDateParams>

/** A time preset's parameters: `@maskito/kit`'s, each optional. */
export type TimeMaskParams = Partial<MaskitoTimeParams>

/** A date and time preset's parameters: `@maskito/kit`'s, each optional. */
export type DateTimeMaskParams = Partial<MaskitoDateTimeParams>

/** A date range preset's parameters: `@maskito/kit`'s, each optional. */
export type DateRangeMaskParams = Partial<MaskitoDateRangeParams>

/**
 * Without a mode or a locale, dates are written `dd/mm/yyyy`, with slashes, as the mode's name
 * says (`@maskito/kit` would separate them with dots).
 */
const DATE_MODE: MaskitoDateMode = 'dd/mm/yyyy'
const DATE_SEPARATOR = '/'
/** Without a mode, times are `HH:MM`. */
const TIME_MODE: MaskitoTimeMode = 'HH:MM'

function dateParams(params: DateMaskParams): MaskitoDateParams {
  if (params.locale) return params as MaskitoDateParams
  return {
    ...params,
    mode: params.mode ?? DATE_MODE,
    separator: params.separator ?? DATE_SEPARATOR,
  }
}

function timeParams(params: TimeMaskParams): MaskitoTimeParams {
  return { ...params, mode: params.mode ?? TIME_MODE }
}

/**
 * A number: digits, a decimal separator, a thousands separator, and a minus sign, a prefix or a
 * postfix if you give them (`@maskito/kit`'s `maskitoNumber`).
 *
 *   <MaskedInput @mask={{numberMask maximumFractionDigits=2 prefix="$"}} />
 *
 * `min` and `max` clamp it, and `locale` takes its separators from that locale.
 */
export function numberMask(params: MaskitoNumberParams = {}): MaskitoOptions {
  return maskitoNumber(params)
}

/**
 * A date (`@maskito/kit`'s `maskitoDate`): `dd/mm/yyyy` unless `mode` (`mm/dd/yyyy`,
 * `yyyy/mm/dd`, `mm/yy`…) says otherwise, separated by `separator` (default `/`), within `min`
 * and `max`. With `locale` (`en-US`, `de-DE`), the order and separator are that locale's.
 */
export function dateMask(params: DateMaskParams = {}): MaskitoOptions {
  return maskitoDate(dateParams(params))
}

/**
 * A time (`@maskito/kit`'s `maskitoTime`): `HH:MM` unless `mode` (`HH:MM:SS`, `HH:MM AA`, `MM:SS`…)
 * says otherwise, with `step` for the arrow keys.
 */
export function timeMask(params: TimeMaskParams = {}): MaskitoOptions {
  return maskitoTime(timeParams(params))
}

/** A date and a time (`@maskito/kit`'s `maskitoDateTime`): `dd/mm/yyyy, HH:MM` by default. */
export function dateTimeMask(params: DateTimeMaskParams = {}): MaskitoOptions {
  const date = params.locale
    ? params
    : {
        ...params,
        dateMode: params.dateMode ?? DATE_MODE,
        dateSeparator: params.dateSeparator ?? DATE_SEPARATOR,
      }
  return maskitoDateTime({
    ...date,
    timeMode: params.timeMode ?? TIME_MODE,
  } as MaskitoDateTimeParams)
}

/** Two dates (`@maskito/kit`'s `maskitoDateRange`): `dd/mm/yyyy – dd/mm/yyyy` by default. */
export function dateRangeMask(params: DateRangeMaskParams = {}): MaskitoOptions {
  const range = params.locale
    ? params
    : {
        ...params,
        mode: params.mode ?? DATE_MODE,
        dateSeparator: params.dateSeparator ?? DATE_SEPARATOR,
      }
  return maskitoDateRange(range as MaskitoDateRangeParams)
}

/**
 * The number a `numberMask` input shows, or `NaN` while it shows none. Give it the preset's
 * parameters, so it reads the same separators.
 *
 *   parseNumber('$1,234.50', { prefix: '$' }) // 1234.5
 */
export function parseNumber(text: string, params: MaskitoNumberParams = {}): number {
  return maskitoParseNumber(text, params)
}

/** A number as a `numberMask` input with these parameters shows it. */
export function formatNumber(number: number | null, params: MaskitoNumberParams = {}): string {
  return maskitoStringifyNumber(number, params)
}

/** The date a `dateMask` input shows, or `null` while it shows no whole date. */
export function parseDate(text: string, params: DateMaskParams = {}): Date | null {
  return maskitoParseDate(text, dateParams(params))
}

/** A date as a `dateMask` input with these parameters shows it. */
export function formatDate(date: Date, params: DateMaskParams = {}): string {
  return maskitoStringifyDate(date, dateParams(params))
}

/** The time a `timeMask` input shows, in milliseconds since midnight. */
export function parseTime(text: string, params: TimeMaskParams = {}): number {
  return maskitoParseTime(text, timeParams(params))
}

/** A time, in milliseconds since midnight, as a `timeMask` input with these parameters shows it. */
export function formatTime(milliseconds: number, params: TimeMaskParams = {}): string {
  return maskitoStringifyTime(milliseconds, timeParams(params))
}
