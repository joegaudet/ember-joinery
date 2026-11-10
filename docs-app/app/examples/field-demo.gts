import {
  Button,
  Checkbox,
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSeparator,
  FieldSet,
  Input,
  Select,
  Textarea,
} from '@ember-joinery/ember'

const months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']

const years = ['2024', '2025', '2026', '2027', '2028', '2029']

<template>
  <div class="w-full max-w-md">
    <form>
      <FieldGroup>
        <FieldSet>
          <FieldLegend>Payment Method</FieldLegend>
          <FieldDescription>
            All transactions are secure and encrypted
          </FieldDescription>
          <FieldGroup>
            <Field>
              <FieldLabel for="checkout-7j9-card-name-43j">
                Name on Card
              </FieldLabel>
              <Input id="checkout-7j9-card-name-43j" placeholder="Evil Rabbit" required />
            </Field>
            <Field>
              <FieldLabel for="checkout-7j9-card-number-uw1">
                Card Number
              </FieldLabel>
              <Input id="checkout-7j9-card-number-uw1" placeholder="1234 5678 9012 3456" required />
              <FieldDescription>
                Enter your 16-digit card number
              </FieldDescription>
            </Field>
            <div class="grid grid-cols-3 gap-4">
              <Field>
                <FieldLabel for="checkout-exp-month-ts6">
                  Month
                </FieldLabel>
                <Select @defaultValue="" as |s|>
                  <s.Trigger id="checkout-exp-month-ts6">
                    <s.Value @placeholder="MM" />
                  </s.Trigger>
                  <s.Content>
                    <s.Group>
                      {{#each months as |month|}}
                        <s.Item @value={{month}}>{{month}}</s.Item>
                      {{/each}}
                    </s.Group>
                  </s.Content>
                </Select>
              </Field>
              <Field>
                <FieldLabel for="checkout-7j9-exp-year-f59">
                  Year
                </FieldLabel>
                <Select @defaultValue="" as |s|>
                  <s.Trigger id="checkout-7j9-exp-year-f59">
                    <s.Value @placeholder="YYYY" />
                  </s.Trigger>
                  <s.Content>
                    <s.Group>
                      {{#each years as |year|}}
                        <s.Item @value={{year}}>{{year}}</s.Item>
                      {{/each}}
                    </s.Group>
                  </s.Content>
                </Select>
              </Field>
              <Field>
                <FieldLabel for="checkout-7j9-cvv">CVV</FieldLabel>
                <Input id="checkout-7j9-cvv" placeholder="123" required />
              </Field>
            </div>
          </FieldGroup>
        </FieldSet>
        <FieldSeparator />
        <FieldSet>
          <FieldLegend>Billing Address</FieldLegend>
          <FieldDescription>
            The billing address associated with your payment method
          </FieldDescription>
          <FieldGroup>
            <Field @orientation="horizontal">
              <Checkbox id="checkout-7j9-same-as-shipping-wgm" @defaultChecked={{true}} />
              <FieldLabel for="checkout-7j9-same-as-shipping-wgm" class="font-normal">
                Same as shipping address
              </FieldLabel>
            </Field>
          </FieldGroup>
        </FieldSet>
        <FieldSet>
          <FieldGroup>
            <Field>
              <FieldLabel for="checkout-7j9-optional-comments">
                Comments
              </FieldLabel>
              <Textarea
                id="checkout-7j9-optional-comments"
                placeholder="Add any additional comments"
                class="resize-none"
              />
            </Field>
          </FieldGroup>
        </FieldSet>
        <Field @orientation="horizontal">
          <Button type="submit">Submit</Button>
          <Button @variant="outline" type="button">
            Cancel
          </Button>
        </Field>
      </FieldGroup>
    </form>
  </div>
</template>
