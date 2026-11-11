import type { TOC } from '@ember/component/template-only'
import type { ControlSignature } from '@ember-formwright/ember'
import Currency from '@ember-formwright/ember/controls/currency'
import { inputClasses } from '@ember-joinery/ember'

export interface CurrencyControlSignature {
  Args: ControlSignature<number | null>['Args']
  /** Formwright's currency `<input>`. */
  Element: HTMLElement
}

const CLASSES = inputClasses()

/**
 * Formwright's `currency` control in Joinery's Input: it stores a number, shows it formatted in
 * `@currency` (USD by default) and `@locale` while it isn't being edited, and takes what is
 * typed as the browser's locale writes numbers. Formwright's own control, drawn as Joinery's
 * Input (`jn-input`, `data-slot="input"`).
 */
export const CurrencyControl: TOC<CurrencyControlSignature> = <template>
  <Currency
    @id={{@id}}
    @name={{@name}}
    @type={{@type}}
    @value={{@value}}
    @onChange={{@onChange}}
    @disabled={{@disabled}}
    @readonly={{@readonly}}
    @required={{@required}}
    @invalid={{@invalid}}
    @describedBy={{@describedBy}}
    @placeholder={{@placeholder}}
    @label={{@label}}
    @min={{@min}}
    @max={{@max}}
    @step={{@step}}
    @currency={{@currency}}
    @locale={{@locale}}
    class={{CLASSES}}
    data-slot="input"
    data-test-jn="input"
    ...attributes
  />
</template>
