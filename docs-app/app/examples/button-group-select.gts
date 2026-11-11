import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ArrowRight } from 'lucide'
import { Button, ButtonGroup, Icon, Input, Select } from '@ember-joinery/ember'

const CURRENCIES = [
  { value: '$', label: 'US Dollar' },
  { value: '€', label: 'Euro' },
  { value: '£', label: 'British Pound' },
]

export default class ButtonGroupSelect extends Component {
  @tracked currency = '$'

  setCurrency = (currency: string) => (this.currency = currency)

  <template>
    {{!
      Upstream's trigger and input have no names, but for the input's placeholder; these are
      named (aria-label), so the audit passes.
    }}
    <ButtonGroup>
      <ButtonGroup>
        <Select @value={{this.currency}} @onValueChange={{this.setCurrency}} as |s|>
          <s.Trigger class="font-mono" aria-label="Currency">{{this.currency}}</s.Trigger>
          <s.Content class="min-w-24">
            <s.Group>
              {{#each CURRENCIES as |currency|}}
                <s.Item @value={{currency.value}}>
                  {{currency.value}}
                  <span class="text-muted-foreground">
                    {{currency.label}}
                  </span>
                </s.Item>
              {{/each}}
            </s.Group>
          </s.Content>
        </Select>
        <Input placeholder="10.00" pattern="[0-9]*" aria-label="Amount" />
      </ButtonGroup>
      <ButtonGroup>
        <Button aria-label="Send" @size="icon" @variant="outline">
          <Icon @icon={{ArrowRight}} />
        </Button>
      </ButtonGroup>
    </ButtonGroup>
  </template>
}
