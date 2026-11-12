import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import Currency from '@ember-formwright/ember/controls/currency'
import { inputClasses } from '@ember-joinery/ember'
import { translator } from '@ember-joinery/primitives/i18n'

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
 * Input (`jn-input`, `data-slot="input"`). `@locale` defaults to the app's translator's.
 */
export class CurrencyControl extends Component<CurrencyControlSignature> {
  get locale(): string | undefined {
    return this.args.locale ?? translator(this)?.locale
  }

  <template>
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
      @locale={{this.locale}}
      class={{CLASSES}}
      data-slot="input"
      data-test-jn="input"
      ...attributes
    />
  </template>
}
