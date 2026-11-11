/*
 * Reads a form's data out of one of its events, as an object. Ported from form-data-utils
 * 0.6.0's `dataFrom` (MIT, NullVoxPopuli; https://github.com/NullVoxPopuli/form-data-utils),
 * which ember-primitives' Form uses, with one change: a `<button>` counts only as the submitter
 * of a submit event. Joinery's Checkbox, Switch and radio items are buttons that repeat their
 * `name` on a hidden native input (see form-control.ts), and the original treats a named button
 * as that field's value, or fails when a name is shared by a button and an input.
 */

/** One field's value, as `dataFromEvent` reads it. */
export type NativeFormValue =
  | string
  | number
  | boolean
  | Date
  | File
  | null
  | undefined
  | Array<string | boolean | File | null | undefined>

/** A form's data, by field name. */
export type NativeFormData = Record<string, NativeFormValue | FormDataEntryValue>

function getRadioCheckboxValue(element: HTMLInputElement): string | boolean | null | undefined {
  if (element.disabled) return undefined
  if (element.getAttribute('value') === null) return element.checked
  return element.checked ? element.value : null
}

function getSelectValue(field: HTMLSelectElement): string | null | Array<string> {
  if (field.multiple) {
    if (field.selectedIndex === -1) return []
    return [...field.options]
      .filter(option => !option.disabled && option.selected && option.value !== '')
      .map(option => option.value)
  }
  if (field.selectedIndex === -1) return null
  let value: string | null = null
  for (const option of field.options) {
    if (!option.disabled && option.selected) value = option.value === '' ? null : option.value
  }
  return value
}

/**
 * The data of the form that is `event.currentTarget`: each named field's value, converted as
 * form-data-utils converts it (numbers, dates, checkboxes, radios, selects and files), with a
 * submit event's submitter included.
 */
export function dataFrom(event: {
  currentTarget: EventTarget | null
  submitter?: HTMLElement | null
}): NativeFormData {
  const form = event.currentTarget
  if (!(form instanceof HTMLFormElement)) {
    throw new Error('dataFromEvent: the event’s currentTarget must be a <form>')
  }
  const submitter = event.submitter ?? null
  const data: NativeFormData = Object.fromEntries(new FormData(form, submitter).entries())

  for (const field of form.elements) {
    const name = field.getAttribute('name')
    if (!name) continue

    if (field instanceof HTMLButtonElement) {
      if (field === submitter) data[name] = field.value || null
      continue
    }

    if (!(name in data)) data[name] = null

    if (field instanceof HTMLSelectElement) {
      data[name] = getSelectValue(field)
      continue
    }

    if (!(field instanceof HTMLInputElement)) continue

    const related = [...form.elements].filter(
      (element): element is HTMLInputElement =>
        element instanceof HTMLInputElement && element.name === name,
    )
    const several = related.length > 1

    switch (field.type) {
      case 'number':
      case 'range':
        data[name] = Number.isNaN(field.valueAsNumber) ? null : field.valueAsNumber
        break
      case 'date':
        data[name] = field.valueAsDate
        break
      case 'datetime-local':
        data[name] = Number.isNaN(field.valueAsNumber) ? null : new Date(field.valueAsNumber)
        break
      case 'checkbox':
        data[name] = several
          ? related.filter(box => box.checked).map(getRadioCheckboxValue)
          : getRadioCheckboxValue(field)
        break
      case 'radio': {
        const radio = several ? related.find(item => item.checked) : field
        data[name] = radio ? getRadioCheckboxValue(radio) : null
        break
      }
      case 'file':
        data[name] =
          field.files && field.files.length > 0
            ? field.multiple
              ? [...field.files]
              : (field.files[0] ?? null)
            : field.multiple
              ? []
              : null
        break
    }
  }
  return data
}
