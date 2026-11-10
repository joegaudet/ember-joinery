import type { MaskitoOptions } from '@maskito/core'
import { maskitoAddOnFocusPlugin, maskitoRemoveOnBlurPlugin } from '@maskito/kit'
import { maskitoPhone } from '@maskito/phone'
import minMetadata from 'libphonenumber-js/min/metadata'
import {
  AsYouType,
  getCountries,
  getCountryCallingCode,
  isValidPhoneNumber,
  parsePhoneNumberFromString,
  type CountryCode,
  type MetadataJson,
} from 'libphonenumber-js/core'

export type { CountryCode, MetadataJson }

/** libphonenumber-js's `min` metadata, the default everywhere here. */
export const phoneMetadata = minMetadata as unknown as MetadataJson

/** What a phone mask is for: a country, shown with or without its calling code. */
export interface PhoneMaskOptions {
  /** Show the national format, `(212) 555-0123`, rather than `+1 212 555-0123`. */
  national?: boolean
  /** libphonenumber-js metadata. Default its `min` metadata. */
  metadata?: MetadataJson
}

/**
 * The Maskito options for one country's phone numbers (`@maskito/phone`, strict). In the
 * international format, its calling code is fixed in front: it goes in when the input takes
 * focus, as `@maskito/kit`'s focus plugin puts it (the mask needs it there before the first
 * digit), and comes out again on blur if nothing follows it. Each call makes new options, as a
 * phone mask keeps state of its own.
 */
export function phoneMask(
  country: CountryCode,
  { national = false, metadata = phoneMetadata }: PhoneMaskOptions = {},
): MaskitoOptions {
  const options = maskitoPhone({
    countryIsoCode: country,
    metadata,
    strict: true,
    format: national ? 'NATIONAL' : 'INTERNATIONAL',
  })
  if (national) return options
  const prefix = `+${getCountryCallingCode(country, metadata)} `
  return {
    ...options,
    plugins: [
      ...options.plugins,
      maskitoAddOnFocusPlugin(prefix),
      maskitoRemoveOnBlurPlugin(prefix),
    ],
  }
}

/** Every country the metadata has numbers for, as ISO 3166 codes. */
export function phoneCountries(metadata: MetadataJson = phoneMetadata): CountryCode[] {
  return getCountries(metadata)
}

/** A country's calling code, without the `+`: `1` for `US`, `44` for `GB`. */
export function callingCode(country: CountryCode, metadata: MetadataJson = phoneMetadata): string {
  return getCountryCallingCode(country, metadata)
}

/** A country's flag, as the emoji its code spells in regional indicator letters. */
export function countryFlag(country: string): string {
  return [...country.toUpperCase()]
    .map(letter => String.fromCodePoint(0x1f1e6 + letter.charCodeAt(0) - 65))
    .join('')
}

/** The calling code an E.164 number (whole or begun) starts with, or `undefined`. */
export function callingCodeOf(
  value: string | null | undefined,
  metadata: MetadataJson = phoneMetadata,
): string | undefined {
  if (!value?.startsWith('+')) return undefined
  const formatter = new AsYouType(undefined, metadata)
  formatter.input(value)
  return formatter.getCallingCode()
}

/**
 * The country of an E.164 number: `current` when the number has its calling code (so a
 * Canadian number stays Canadian while `+1` is typed), else the country the number belongs to,
 * else the main country of its calling code (`US` for `+1`, `GB` for `+44`). `undefined` for a
 * number with no calling code yet.
 */
export function countryOfPhone(
  value: string | null | undefined,
  current?: CountryCode,
  metadata: MetadataJson = phoneMetadata,
): CountryCode | undefined {
  const code = callingCodeOf(value, metadata)
  if (!code) return undefined
  if (current && callingCode(current, metadata) === code) return current
  const parsed = parsePhoneNumberFromString(value!, metadata)
  if (parsed?.country) return parsed.country
  const main = (metadata as { country_calling_codes?: Record<string, string[]> })
    .country_calling_codes?.[code]?.[0]
  return main as CountryCode | undefined
}

/**
 * Whether a stored number is a valid phone number, for a validator. A number without a `+`
 * is read as `country`'s. Uses libphonenumber-js's `min` metadata unless given other metadata,
 * which checks a number's length for its country.
 *
 *   isValidPhone('+12125550123') // true
 */
export function isValidPhone(
  value: string | null | undefined,
  country?: CountryCode,
  metadata: MetadataJson = phoneMetadata,
): boolean {
  if (!value) return false
  return isValidPhoneNumber(value, { defaultCountry: country }, metadata)
}

/**
 * A stored number in international format (`+1 212 555 0123`), to show it outside an input.
 * Anything that doesn't parse is shown as it is.
 */
export function formatPhone(
  value: string | null | undefined,
  metadata: MetadataJson = phoneMetadata,
): string {
  if (!value) return ''
  return parsePhoneNumberFromString(value, metadata)?.formatInternational() ?? value
}
