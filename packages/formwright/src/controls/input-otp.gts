import Component from '@glimmer/component'
import type { ControlSignature, LengthArgs } from '@ember-formwright/ember'
import { InputOTP, type InputOTPParts } from '@ember-joinery/ember'

export interface InputOTPControlSignature {
  Args: ControlSignature<string>['Args'] &
    Pick<LengthArgs, 'maxLength'> & {
      /**
       * How many slots each group holds, with a separator between groups: `[3, 3]` shows two
       * groups of three. Default: one group of `@maxLength` slots.
       */
      groups?: readonly number[]
      /** The characters it takes, as a regular expression's source (`REGEXP_ONLY_DIGITS`). */
      pattern?: string
      /** Called with the code once every slot is filled. */
      onComplete?: (code: string) => void
    }
  Blocks: {
    /** The slots, groups and separators, laid out as Input OTP's: `<otp.Slot @index={{0}} />`. */
    default: [otp: InputOTPParts]
  }
  /** The one native `<input>` that holds the code, which the field's label names. */
  Element: HTMLInputElement
}

interface SlotGroup {
  slots: number[]
  separated: boolean
}

/**
 * Joinery's Input OTP as a Formwright control, `@control="input-otp"`: a one-time code of
 * `@maxLength` characters (6 by default) in slots, stored as a string. `@groups` splits the slots
 * with separators; a block lays them out yourself, with Input OTP's parts.
 */
export class InputOTPControl extends Component<InputOTPControlSignature> {
  get maxLength(): number {
    return this.args.maxLength ?? 6
  }

  get slotGroups(): SlotGroup[] {
    const sizes = this.args.groups?.length ? this.args.groups : [this.maxLength]
    let index = 0
    return sizes.map((size, group) => ({
      slots: Array.from({ length: size }, () => index++),
      separated: group > 0,
    }))
  }

  onValueChange = (code: string): void => this.args.onChange(code)

  <template>
    <InputOTP
      @maxLength={{this.maxLength}}
      @value={{if @value @value ""}}
      @onValueChange={{this.onValueChange}}
      @onComplete={{@onComplete}}
      @pattern={{@pattern}}
      id={{@id}}
      name={{@name}}
      disabled={{if @readonly true @disabled}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      as |otp|
    >
      {{#if (has-block)}}
        {{yield otp}}
      {{else}}
        {{#each this.slotGroups as |group|}}
          {{#if group.separated}}<otp.Separator />{{/if}}
          <otp.Group>
            {{#each group.slots as |index|}}
              <otp.Slot @index={{index}} />
            {{/each}}
          </otp.Group>
        {{/each}}
      {{/if}}
    </InputOTP>
  </template>
}
