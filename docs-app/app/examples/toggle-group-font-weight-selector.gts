import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldLabel, ToggleGroup } from '@ember-joinery/ember'

export default class ToggleGroupFontWeightSelector extends Component {
  @tracked fontWeight = 'normal'

  setFontWeight = (value: string) => (this.fontWeight = value)

  <template>
    <Field>
      {{!
        Upstream's label names nothing: a <label> can't label a group. Joinery's gives it an id
        and the group aria-labelledby, so the group is called Font Weight.
      }}
      <FieldLabel id="font-weight-label">Font Weight</FieldLabel>
      <ToggleGroup
        @type="single"
        @value={{this.fontWeight}}
        @onValueChange={{this.setFontWeight}}
        @variant="outline"
        @spacing={{2}}
        @size="lg"
        aria-labelledby="font-weight-label"
        as |g|
      >
        <g.Item
          @value="light"
          aria-label="Light"
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-light">Aa</span>
          <span class="text-xs text-muted-foreground">Light</span>
        </g.Item>
        <g.Item
          @value="normal"
          aria-label="Normal"
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-normal">Aa</span>
          <span class="text-xs text-muted-foreground">Normal</span>
        </g.Item>
        <g.Item
          @value="medium"
          aria-label="Medium"
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-medium">Aa</span>
          <span class="text-xs text-muted-foreground">Medium</span>
        </g.Item>
        <g.Item
          @value="bold"
          aria-label="Bold"
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-bold">Aa</span>
          <span class="text-xs text-muted-foreground">Bold</span>
        </g.Item>
      </ToggleGroup>
      <FieldDescription>
        Use
        <code class="rounded-md bg-muted px-1 py-0.5 font-mono">font-{{this.fontWeight}}</code>
        to set the font weight.
      </FieldDescription>
    </Field>
  </template>
}
