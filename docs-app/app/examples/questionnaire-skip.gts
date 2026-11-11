import Component from '@glimmer/component'
import { Questionnaire, toast, type QuestionnaireItemStatus } from '@ember-joinery/ember'

const items = [
  { name: 'task', required: true },
  { name: 'constraints' },
  { name: 'review', required: true },
]

export default class QuestionnaireSkipExample extends Component {
  constraintStatus: QuestionnaireItemStatus = 'unanswered'

  setConstraintStatus = (status: QuestionnaireItemStatus) => (this.constraintStatus = status)

  handleSubmit = (event: SubmitEvent) => {
    event.preventDefault()

    const formData = new FormData(event.currentTarget as HTMLFormElement)
    const answers = {
      task: formData.get('task'),
      constraints: formData.get('constraints'),
      constraintStatus: this.constraintStatus,
      review: formData.get('review'),
    }

    toast('Agent brief submitted', {
      description: `Task: ${String(answers.task ?? 'None')} · Constraints: ${
        answers.constraintStatus === 'skipped' ? 'Skipped' : String(answers.constraints ?? 'None')
      } · Review: ${String(answers.review ?? 'None')}`,
    })
  }

  <template>
    <Questionnaire
      class="mx-auto max-w-md"
      @defaultItem="task"
      @items={{items}}
      @onSubmit={{this.handleSubmit}}
      as |q|
    >
      <q.Progress />

      <q.Item @name="task" @required={{true}} as |i|>
        <i.Title>What kind of change is this?</i.Title>
        <i.Description>
          Choose the category that best describes the work.
        </i.Description>
        <i.Choices>
          <i.Choice @value="feature">New feature</i.Choice>
          <i.Choice @value="fix">Bug fix</i.Choice>
          <i.Choice @value="refactor">Refactor</i.Choice>
        </i.Choices>
        <i.Error />
      </q.Item>

      <q.Item @name="constraints" @onStatusChange={{this.setConstraintStatus}} as |i|>
        <i.Title>
          Are there any implementation constraints?
        </i.Title>
        <i.Description>
          Answer if needed, or intentionally skip this question.
        </i.Description>
        <i.Choices>
          <i.Choice @value="no-dependencies">
            Do not add dependencies
          </i.Choice>
          <i.Choice @value="no-migrations">
            Do not change the database
          </i.Choice>
          <i.Choice @value="preserve-api">
            Preserve the public API
          </i.Choice>
          <i.Input
            aria-label="Another implementation constraint"
            placeholder="Describe another constraint…"
          />
        </i.Choices>
      </q.Item>

      <q.Item @name="review" @required={{true}} as |i|>
        <i.Title>
          How should the work be reviewed?
        </i.Title>
        <i.Description>
          Choose the checks the agent should complete before handoff.
        </i.Description>
        <i.Choices>
          <i.Choice @value="tests">
            Run the test suite
          </i.Choice>
          <i.Choice @value="diff">
            Review the final diff
          </i.Choice>
          <i.Choice @value="both">
            Tests and diff review
          </i.Choice>
        </i.Choices>
        <i.Error />
      </q.Item>

      <q.Actions>
        <q.Previous />
        <q.Skip />
        <q.Next>Next</q.Next>
        <q.Submit>Submit brief</q.Submit>
      </q.Actions>
    </Questionnaire>
  </template>
}
