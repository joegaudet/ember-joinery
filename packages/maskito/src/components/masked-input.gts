import type { TOC } from '@ember/component/template-only'
import type { MaskitoOptions } from '@maskito/core'
import { nativeValue, type NativeValueArgs } from '@ember-joinery/primitives/native-value'
import { inputClasses } from '@ember-joinery/ember/components/input'
import { maskito, maskText } from '../maskito.ts'

export interface MaskedInputSignature {
  Args: NativeValueArgs & {
    /**
     * The Maskito options: a preset's (`numberMask`, `dateMask`, `timeMask`…) or your own
     * (`{ mask: ['(', /\d/, /\d/, /\d/, ')', …] }`). Without it, the input takes anything.
     */
    mask?: MaskitoOptions | null
    /** The input's name, for its harness (`data-test-jn-name`). Its form field name is `name`. */
    name?: string
  }
  /** A native `<input>`: give it `placeholder`, `inputmode`, `disabled`, `aria-invalid`… */
  Element: HTMLInputElement
}

const CLASSES = inputClasses()

/**
 * A text input that masks what is typed in it, with [Maskito](https://maskito.dev): Joinery's
 * Input, in shadcn's look, with a mask on it.
 *
 *   <MaskedInput @mask={{numberMask maximumFractionDigits=2}} @onValueChange={{this.setPrice}} />
 *   <MaskedInput @mask={{this.phoneMask}} @defaultValue="5551234567" placeholder="(555) 555-5555" />
 *
 * Its value is the masked text, controlled or not (`@value`, `@defaultValue`,
 * `@onValueChange`), as Input's is. A value you pass is shown masked: `5551234567` shows as
 * `(555) 123-4567`, and `@onValueChange` hears the masked text the next time it changes.
 */
const MaskedInput: TOC<MaskedInputSignature> = <template>
  <input
    class={{CLASSES}}
    data-slot="input"
    data-test-jn="masked-input"
    data-test-jn-name={{@name}}
    {{nativeValue
      value=(maskText @value @mask)
      defaultValue=(maskText @defaultValue @mask)
      onValueChange=@onValueChange
    }}
    {{maskito @mask}}
    ...attributes
  />
</template>

export default MaskedInput
