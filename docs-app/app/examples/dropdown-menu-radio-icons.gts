import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Building2, CreditCard, Wallet } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

export default class DropdownMenuRadioIcons extends Component {
  @tracked paymentMethod = 'card'

  setPaymentMethod = (method: string) => (this.paymentMethod = method)

  <template>
    <DropdownMenu as |m|>
      <Button @variant="outline" {{m.trigger}}>Payment Method</Button>
      <m.Content class="min-w-56">
        <m.Group>
          <m.Label>Select Payment Method</m.Label>
          <m.RadioGroup
            @value={{this.paymentMethod}}
            @onValueChange={{this.setPaymentMethod}}
            as |g|
          >
            <g.Item @value="card">
              <Icon @icon={{CreditCard}} />
              Credit Card
            </g.Item>
            <g.Item @value="paypal">
              <Icon @icon={{Wallet}} />
              PayPal
            </g.Item>
            <g.Item @value="bank">
              <Icon @icon={{Building2}} />
              Bank Transfer
            </g.Item>
          </m.RadioGroup>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  </template>
}
