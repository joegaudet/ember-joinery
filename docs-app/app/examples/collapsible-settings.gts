import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Maximize, Minimize } from 'lucide'
import {
  Button,
  Card,
  Collapsible,
  Field,
  FieldGroup,
  FieldLabel,
  Icon,
  Input,
} from '@ember-joinery/ember'

export default class CollapsibleSettings extends Component {
  @tracked isOpen = false

  setIsOpen = (open: boolean) => (this.isOpen = open)

  <template>
    {{!
      Upstream gives all four inputs id="radius", and their labels' htmlFor ("radius-x",
      "radius-y") matches none of them, so nothing names the inputs. Here each input has an id
      of its own and its label points at it, and the icon-only trigger, which upstream leaves
      unnamed, has aria-label, so the audit passes.
    }}
    <Card class="mx-auto w-full max-w-xs" @size="sm" as |card|>
      <card.Header>
        <card.Title>Radius</card.Title>
        <card.Description>Set the corner radius of the element.</card.Description>
      </card.Header>
      <card.Content>
        <Collapsible
          @open={{this.isOpen}}
          @onOpenChange={{this.setIsOpen}}
          class="flex items-start gap-2"
          as |c|
        >
          <FieldGroup class="grid w-full grid-cols-2 gap-2">
            <Field>
              <FieldLabel for="radius-x" class="sr-only">
                Radius X
              </FieldLabel>
              <Input id="radius-x" placeholder="0" @defaultValue="0" />
            </Field>
            <Field>
              <FieldLabel for="radius-y" class="sr-only">
                Radius Y
              </FieldLabel>
              <Input id="radius-y" placeholder="0" @defaultValue="0" />
            </Field>
            <c.Content class="col-span-full grid grid-cols-subgrid gap-2">
              <Field>
                <FieldLabel for="radius-x-end" class="sr-only">
                  Radius X
                </FieldLabel>
                <Input id="radius-x-end" placeholder="0" @defaultValue="0" />
              </Field>
              <Field>
                <FieldLabel for="radius-y-end" class="sr-only">
                  Radius Y
                </FieldLabel>
                <Input id="radius-y-end" placeholder="0" @defaultValue="0" />
              </Field>
            </c.Content>
          </FieldGroup>
          <Button
            @variant="outline"
            @size="icon"
            aria-label="Toggle the radius settings"
            {{c.trigger}}
          >
            {{#if this.isOpen}}
              <Icon @icon={{Minimize}} />
            {{else}}
              <Icon @icon={{Maximize}} />
            {{/if}}
          </Button>
        </Collapsible>
      </card.Content>
    </Card>
  </template>
}
