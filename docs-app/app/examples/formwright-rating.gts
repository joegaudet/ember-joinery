import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { Field, FieldGroup, asButton } from '@ember-joinery/ember'

class Review {
  @tracked rating: number | null = null
  @tracked value: number | null = 3.5
}

const requireRating = (review: Review): ErrorMap =>
  review.rating ? {} : { rating: ['Pick a rating.'] }

/*
 * Joinery's own: a `rating` field stores the rating picked, or `null` for none, and picking
 * it again clears it. Each star is a radio, described by the field's hint and errors, and the
 * field's label names the stars' group. `@step={{0.5}}` gives half stars.
 */
export default class FormwrightRating extends Component {
  model = new Review()

  <template>
    <Form
      @model={{this.model}}
      @name="review"
      @validator={{requireRating}}
      class="w-full max-w-xs"
      as |f|
    >
      <FieldGroup>
        <f.Field
          @for="rating"
          @control="rating"
          @label="Rating"
          @hint="How would you rate it overall?"
        />
        <f.Field @for="value" @control="rating" @label="Value for money" @step={{0.5}} as |field|>
          <field.Control @size="sm" />
        </f.Field>
        <Field @orientation="horizontal">
          <f.Submit {{asButton}}>Submit review</f.Submit>
        </Field>
      </FieldGroup>
    </Form>
  </template>
}
