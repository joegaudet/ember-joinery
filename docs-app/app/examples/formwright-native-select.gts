import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { FieldGroup } from '@ember-joinery/ember'

const statuses = [
  { id: 'todo', label: 'Todo' },
  { id: 'in-progress', label: 'In Progress' },
  { id: 'done', label: 'Done' },
  { id: 'cancelled', label: 'Cancelled' },
]

/*
 * Joinery's own: a `native-select` field is Joinery's Native Select, a native `<select>`, and a
 * `number` and a `currency` field are Joinery's Input.
 */
export default class FormwrightNativeSelect extends Component {
  model = { status: 'todo', estimate: 3, budget: 1200 }

  <template>
    <Form @model={{this.model}} @name="task" class="w-full max-w-xs" as |f|>
      <FieldGroup>
        <f.Field
          @for="status"
          @control="native-select"
          @label="Status"
          @placeholder="Select status"
          @options={{statuses}}
          @storeKey={{true}}
        />
        <f.Field @for="estimate" @control="number" @label="Estimate (days)" @min={{1}} />
        <f.Field
          @for="budget"
          @control="currency"
          @label="Budget"
          @currency="USD"
          @locale="en-US"
        />
      </FieldGroup>
    </Form>
  </template>
}
