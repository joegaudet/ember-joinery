import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { InputOTP } from '@ember-joinery/ember'

export default class InputOTPInvalid extends Component {
  @tracked value = '000000'

  setValue = (value: string) => (this.value = value)

  <template>
    {{! aria-invalid="true": React renders upstream's bare aria-invalid as "true"; a bare one here is empty, which ARIA reads as false. }}
    <InputOTP @maxLength={{6}} @value={{this.value}} @onValueChange={{this.setValue}} as |otp|>
      <otp.Group>
        <otp.Slot @index={{0}} aria-invalid="true" />
        <otp.Slot @index={{1}} aria-invalid="true" />
      </otp.Group>
      <otp.Separator />
      <otp.Group>
        <otp.Slot @index={{2}} aria-invalid="true" />
        <otp.Slot @index={{3}} aria-invalid="true" />
      </otp.Group>
      <otp.Separator />
      <otp.Group>
        <otp.Slot @index={{4}} aria-invalid="true" />
        <otp.Slot @index={{5}} aria-invalid="true" />
      </otp.Group>
    </InputOTP>
  </template>
}
