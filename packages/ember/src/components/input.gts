import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import { nativeValue, type NativeValueArgs } from '@ember-joinery/primitives/native-value'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/** What both `<Input>` and the `asInput` modifier take. */
export interface InputOptions {
  /** The input's name, for its harness (`data-test-jn-name`). Its form field name is `name`. */
  name?: string
}

/** The classes an input renders: upstream's semantic class, renamed `jn-input`. */
export function inputClasses(): string {
  return 'jn-input'
}

/** The data attributes an input renders: upstream's, and its harness's. */
export interface InputAttributes {
  'data-slot': 'input'
  'data-test-jn': 'input'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes an input renders, as upstream's and for its harness. */
export function inputAttributes({ name }: InputOptions = {}): InputAttributes {
  return { 'data-slot': 'input', 'data-test-jn': 'input', 'data-test-jn-name': name }
}

/**
 * Makes an `<input>` of your own look like Joinery's, such as one another library renders: it
 * adds the input's class and attributes, and keeps them current. It leaves the value to the
 * element; add `{{nativeValue}}` from `@ember-joinery/primitives/native-value` for `@value`'s
 * behaviour.
 *
 *   <MaskedInput {{asInput name="phone"}} />
 *
 * It isn't named `input`: in a template, a binding by that name would turn every `<input>`
 * element into a call to it.
 */
export const asInput: PartModifier<HTMLInputElement, InputOptions> = part<
  HTMLInputElement,
  InputOptions
>(options => ({ class: inputClasses(), attributes: inputAttributes(options) }))

export interface InputSignature {
  Args: NativeValueArgs & InputOptions
  /** A native `<input>`: give it `type`, `placeholder`, `disabled`, `aria-invalid` and the rest. */
  Element: HTMLInputElement
}

const CLASSES = inputClasses()

/**
 * A text input for forms and user data entry: shadcn's Input. It renders a native `<input>`,
 * so `type`, `placeholder`, `disabled`, `required`, `aria-invalid` and listeners go on it as
 * attributes, and its value is controlled or not, as in Radix:
 *
 *   <Input @value={{this.email}} @onValueChange={{this.setEmail}} type="email" />
 *   <Input @defaultValue="Ada" name="first-name" />
 *
 * Mark an error with `aria-invalid="true"` (an empty `aria-invalid` means false).
 */
const Input: TOC<InputSignature> = <template>
  {{#let (inputAttributes name=@name) as |attributes|}}
    <input
      class={{CLASSES}}
      data-slot={{get attributes "data-slot"}}
      data-test-jn={{get attributes "data-test-jn"}}
      data-test-jn-name={{get attributes "data-test-jn-name"}}
      {{nativeValue value=@value defaultValue=@defaultValue onValueChange=@onValueChange}}
      ...attributes
    />
  {{/let}}
</template>

export default Input
