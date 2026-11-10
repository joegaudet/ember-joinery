import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Questionnaire, toast, type QuestionnaireItemStatus } from '@ember-joinery/ember'

const items = [
  { name: 'permission', required: true },
  { name: 'verification', required: true },
]

type ItemName = 'permission' | 'verification'

export default class QuestionnaireNavigationState extends Component {
  @tracked item: ItemName = 'permission'
  @tracked statuses: Record<ItemName, QuestionnaireItemStatus> = {
    permission: 'unanswered',
    verification: 'unanswered',
  }

  get unanswered(): boolean {
    return this.statuses[this.item] === 'unanswered'
  }

  setItem = (item: string) => (this.item = item as ItemName)

  setStatus = (name: ItemName, status: QuestionnaireItemStatus) => {
    this.statuses = { ...this.statuses, [name]: status }
  }

  setPermission = (status: QuestionnaireItemStatus) => this.setStatus('permission', status)

  setVerification = (status: QuestionnaireItemStatus) => this.setStatus('verification', status)

  handleSubmit = (event: SubmitEvent) => {
    event.preventDefault()

    const formData = new FormData(event.currentTarget as HTMLFormElement)

    toast('Permissions saved', {
      description: `Permission: ${String(formData.get('permission') ?? 'None')} · Verification: ${String(formData.get('verification') ?? 'None')}`,
    })
  }

  <template>
    <Questionnaire
      class="mx-auto max-w-md"
      @item={{this.item}}
      @items={{items}}
      @onItemChange={{this.setItem}}
      @onSubmit={{this.handleSubmit}}
      as |q|
    >
      <q.Progress />

      <q.Item @name="permission" @required={{true}} @onStatusChange={{this.setPermission}} as |i|>
        <i.Title>What may the agent modify?</i.Title>
        <i.Description>
          Next is intentionally disabled until an answer is selected.
        </i.Description>
        <i.Choices>
          <i.Choice @value="files">Project files</i.Choice>
          <i.Choice @value="tests">
            Project files and tests
          </i.Choice>
          <i.Choice @value="config">
            Files, tests, and configuration
          </i.Choice>
        </i.Choices>
        <i.Error />
      </q.Item>

      <q.Item
        @name="verification"
        @required={{true}}
        @onStatusChange={{this.setVerification}}
        as |i|
      >
        <i.Title>
          What must pass before completion?
        </i.Title>
        <i.Choices>
          <i.Choice @value="tests">Tests</i.Choice>
          <i.Choice @value="types">
            Tests and types
          </i.Choice>
          <i.Choice @value="all">
            Tests, types, and visual QA
          </i.Choice>
        </i.Choices>
        <i.Error />
      </q.Item>

      <q.Actions>
        <q.Previous />
        <q.Next
          class="data-[status=unanswered]:opacity-50"
          @disabled={{this.unanswered}}
          @variant="secondary"
        >
          Next
        </q.Next>
        <q.Submit @disabled={{this.unanswered}}>
          Save permissions
        </q.Submit>
      </q.Actions>
    </Questionnaire>
  </template>
}
