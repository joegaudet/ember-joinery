import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { InputOTP } from '@ember-joinery/ember'

export default class InputOTPControlled extends Component {
  @tracked value = ''

  setValue = (value: string) => (this.value = value)

  <template>
    <div class="space-y-2">
      <InputOTP @maxLength={{6}} @value={{this.value}} @onValueChange={{this.setValue}} as |otp|>
        <otp.Group>
          <otp.Slot @index={{0}} />
          <otp.Slot @index={{1}} />
          <otp.Slot @index={{2}} />
          <otp.Slot @index={{3}} />
          <otp.Slot @index={{4}} />
          <otp.Slot @index={{5}} />
        </otp.Group>
      </InputOTP>
      <div class="text-center text-sm">
        {{#if this.value}}
          You entered:
          {{this.value}}
        {{else}}
          Enter your one-time password.
        {{/if}}
      </div>
    </div>
  </template>
}
