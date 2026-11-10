import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Questionnaire, toast, type QuestionnaireItemDefinition } from '@ember-joinery/ember'

export default class QuestionnaireConditional extends Component {
  @tracked runtime = 'local'

  get items(): QuestionnaireItemDefinition[] {
    return [
      { name: 'runtime', required: true },
      { disabled: this.runtime !== 'cloud', name: 'environment', required: true },
      { name: 'approval', required: true },
    ]
  }

  get isLocal(): boolean {
    return this.runtime === 'local'
  }

  get isCloud(): boolean {
    return this.runtime === 'cloud'
  }

  chooseLocal = () => (this.runtime = 'local')

  chooseCloud = () => (this.runtime = 'cloud')

  handleSubmit = (event: SubmitEvent) => {
    event.preventDefault()

    const formData = new FormData(event.currentTarget as HTMLFormElement)

    toast('Execution plan saved', {
      description: `Runtime: ${String(formData.get('runtime') ?? 'None')} · Environment: ${String(formData.get('environment') ?? 'Not applicable')} · Approval: ${String(formData.get('approval') ?? 'None')}`,
    })
  }

  <template>
    <Questionnaire
      class="mx-auto max-w-md"
      @defaultItem="runtime"
      @items={{this.items}}
      @onSubmit={{this.handleSubmit}}
      as |q|
    >
      <q.Progress />

      <q.Item @name="runtime" @required={{true}} as |i|>
        <i.Title>Where should the agent run?</i.Title>
        <i.Description>
          Cloud runs add an environment question to this flow.
        </i.Description>
        <i.Choices>
          <i.Choice @checked={{this.isLocal}} @value="local" @onCheckedChange={{this.chooseLocal}}>
            Local workspace
          </i.Choice>
          <i.Choice @checked={{this.isCloud}} @value="cloud" @onCheckedChange={{this.chooseCloud}}>
            Cloud workspace
          </i.Choice>
        </i.Choices>
        <i.Error />
      </q.Item>

      <q.Item @disabled={{this.isLocal}} @name="environment" @required={{true}} as |i|>
        <i.Title>
          Which cloud environment should it use?
        </i.Title>
        <i.Choices>
          <i.Choice @value="preview">Preview</i.Choice>
          <i.Choice @value="staging">Staging</i.Choice>
          <i.Choice @value="isolated">
            Isolated sandbox
          </i.Choice>
        </i.Choices>
        <i.Error />
      </q.Item>

      <q.Item @name="approval" @required={{true}} as |i|>
        <i.Title>
          When should the agent request approval?
        </i.Title>
        <i.Choices>
          <i.Choice @value="writes">
            Before writing files
          </i.Choice>
          <i.Choice @value="commands">
            Before running commands
          </i.Choice>
          <i.Choice @value="sensitive">
            Only for sensitive actions
          </i.Choice>
        </i.Choices>
        <i.Error />
      </q.Item>

      <q.Actions>
        <q.Previous />
        <q.Next>Next</q.Next>
        <q.Submit>Save execution plan</q.Submit>
      </q.Actions>
    </Questionnaire>
  </template>
}
