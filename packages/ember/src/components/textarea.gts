import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import { nativeValue, type NativeValueArgs } from '@ember-joinery/primitives/native-value'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/** What both `<Textarea>` and the `asTextarea` modifier take. */
export interface TextareaOptions {
  /** The textarea's name, for its harness (`data-test-jn-name`). Its form field name is `name`. */
  name?: string
}

/** The classes a textarea renders: upstream's semantic class, renamed `jn-textarea`. */
export function textareaClasses(): string {
  return 'jn-textarea'
}

/** The data attributes a textarea renders: upstream's, and its harness's. */
export interface TextareaAttributes {
  'data-slot': 'textarea'
  'data-test-jn': 'textarea'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes a textarea renders, as upstream's and for its harness. */
export function textareaAttributes({ name }: TextareaOptions = {}): TextareaAttributes {
  return { 'data-slot': 'textarea', 'data-test-jn': 'textarea', 'data-test-jn-name': name }
}

/**
 * Makes a `<textarea>` of your own look like Joinery's, such as one an editor library renders:
 * it adds the textarea's class and attributes, and keeps them current. It leaves the value to
 * the element; add `{{nativeValue}}` from `@ember-joinery/primitives/native-value` for
 * `@value`'s behaviour.
 *
 * It isn't named `textarea`: in a template, a binding by that name would turn every
 * `<textarea>` element into a call to it.
 */
export const asTextarea: PartModifier<HTMLTextAreaElement, TextareaOptions> = part<
  HTMLTextAreaElement,
  TextareaOptions
>(options => ({ class: textareaClasses(), attributes: textareaAttributes(options) }))

export interface TextareaSignature {
  Args: NativeValueArgs & TextareaOptions
  /** A native `<textarea>`: give it `placeholder`, `rows`, `disabled`, `aria-invalid` and the rest. */
  Element: HTMLTextAreaElement
}

const CLASSES = textareaClasses()

/**
 * A multi-line text field: shadcn's Textarea. It renders a native `<textarea>` that grows with
 * its text (`field-sizing: content`, from at least 4rem tall), so `placeholder`,
 * `rows`, `disabled`, `aria-invalid` and listeners go on it as attributes, and its value is
 * controlled or not, as in Radix:
 *
 *   <Textarea @value={{this.message}} @onValueChange={{this.setMessage}} />
 *
 * Mark an error with `aria-invalid="true"` (an empty `aria-invalid` means false).
 */
const Textarea: TOC<TextareaSignature> = <template>
  {{#let (textareaAttributes name=@name) as |attributes|}}
    <textarea
      class={{CLASSES}}
      data-slot={{get attributes "data-slot"}}
      data-test-jn={{get attributes "data-test-jn"}}
      data-test-jn-name={{get attributes "data-test-jn-name"}}
      {{nativeValue value=@value defaultValue=@defaultValue onValueChange=@onValueChange}}
      ...attributes
    ></textarea>
  {{/let}}
</template>

export default Textarea
