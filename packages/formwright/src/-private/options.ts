import { get } from '@ember/object'
import { keyOf, labelOf, matches, toStored, type OptionAccessor } from '@ember-formwright/ember'

export { keyOf, labelOf, matches, toStored, type OptionAccessor }

function isObject(value: unknown): value is object {
  return typeof value === 'object' && value !== null
}

/** An option's key as a string: `@optionKey`, else `id`, else `value`, else the option itself. */
export function keyString(option: unknown, accessor?: OptionAccessor): string {
  return String(keyOf(option, accessor) ?? '')
}

/**
 * An option's description, for a choice that shows one under its label: `@optionDescription`
 * (a property name or a function), else the option's own `description`.
 */
export function descriptionOf(option: unknown, accessor?: OptionAccessor): string | undefined {
  let description: unknown
  if (typeof accessor === 'function') description = accessor(option)
  else if (!isObject(option)) return undefined
  else description = get(option, accessor ?? 'description')
  return description === null || description === undefined || description === ''
    ? undefined
    : String(description)
}

/** Whether an option is marked `disabled: true`, as Formwright's controls read it. */
export function isOptionDisabled(option: unknown): boolean {
  return isObject(option) && (option as { disabled?: unknown }).disabled === true
}

/** Whether a value counts as empty: nothing, an empty string or an empty list. */
export function isEmpty(value: unknown): boolean {
  return (
    value === null || value === undefined || value === '' || (Array.isArray(value) && !value.length)
  )
}

/** A number from a Formwright bound (`@min`, `@max`, `@step`), which may be a string. */
export function toNumber(value: number | string | undefined): number | undefined {
  if (value === undefined || value === '') return undefined
  const number = Number(value)
  return Number.isNaN(number) ? undefined : number
}
