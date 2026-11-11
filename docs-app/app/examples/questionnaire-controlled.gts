import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  { name: 'scope', required: true },
  { name: 'checks', required: true },
  { name: 'output', required: true },
]

const itemLabels: Record<string, string> = {
  scope: 'Change scope',
  checks: 'Verification',
  output: 'Final output',
}

export default class QuestionnaireControlled extends Component {
  @tracked item = 'scope'

  setItem = (item: string) => (this.item = item)

  get label(): string | undefined {
    return itemLabels[this.item]
  }

  handleSubmit = (event: SubmitEvent) => {
    event.preventDefault()

    const formData = new FormData(event.currentTarget as HTMLFormElement)

    toast('Agent workflow configured', {
      description: `Scope: ${String(formData.get('scope') ?? 'None')} · Verification: ${String(formData.get('checks') ?? 'None')} · Output: ${String(formData.get('output') ?? 'None')}`,
    })
  }

  <template>
    <div class="relative mx-auto flex h-full w-full max-w-md flex-col">
      <p class="absolute end-0 top-0 text-sm text-muted-foreground" role="status">
        Current checkpoint:
        {{this.label}}
      </p>

      <Questionnaire
        class="mt-auto"
        @item={{this.item}}
        @items={{items}}
        @onItemChange={{this.setItem}}
        @onSubmit={{this.handleSubmit}}
        as |q|
      >
        <q.Progress />

        <q.Item @name="scope" @required={{true}} as |i|>
          <i.Title>What may the agent change?</i.Title>
          <i.Description>
            The host stores the active checkpoint while Questionnaire navigates.
          </i.Description>
          <i.Choices>
            <i.Choice @value="component">
              Only the target component
            </i.Choice>
            <i.Choice @value="tests">
              Component and related tests
            </i.Choice>
            <i.Choice @value="feature">
              The complete feature area
            </i.Choice>
          </i.Choices>
          <i.Error />
        </q.Item>

        <q.Item @name="checks" @required={{true}} as |i|>
          <i.Title>
            Which verification level should it use?
          </i.Title>
          <i.Choices>
            <i.Choice @value="targeted">
              Targeted tests
            </i.Choice>
            <i.Choice @value="package">
              Package tests and typecheck
            </i.Choice>
            <i.Choice @value="full">
              Full workspace verification
            </i.Choice>
          </i.Choices>
          <i.Error />
        </q.Item>

        <q.Item @name="output" @required={{true}} as |i|>
          <i.Title>
            What should the agent return when finished?
          </i.Title>
          <i.Choices>
            <i.Choice @value="summary">
              Concise summary
            </i.Choice>
            <i.Choice @value="diff">
              Summary with changed files
            </i.Choice>
            <i.Choice @value="handoff">
              Detailed implementation handoff
            </i.Choice>
          </i.Choices>
          <i.Error />
        </q.Item>

        <q.Actions>
          <q.Previous />
          <q.Next>Next</q.Next>
          <q.Submit>Save workflow</q.Submit>
        </q.Actions>
      </Questionnaire>
    </div>
  </template>
}
