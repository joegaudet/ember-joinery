import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Button, Dialog, Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  { name: 'scope', required: true },
  { name: 'tests', required: true },
]

export default class QuestionnaireDialog extends Component {
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)

  handleSubmit = (event: SubmitEvent) => {
    event.preventDefault()

    const formData = new FormData(event.currentTarget as HTMLFormElement)

    this.open = false
    toast('Clarification sent', {
      description: `Scope: ${String(formData.get('scope') ?? 'None')} · Verification: ${String(formData.get('tests') ?? 'None')}`,
    })
  }

  <template>
    {{!-- Upstream renders each question's title and description as the dialog's
        (render={<DialogTitle />}), in every item, so two elements share the dialog's title id
        and its description id, and the dialog is always named by the first question. Here the
        dialog's title and description take the questionnaire's parts ({{i.title}},
        {{i.description}}) in the active item only, so each id names one element: the question
        that shows. An inactive item is hidden either way. --}}
    <Dialog @open={{this.open}} @onOpenChange={{this.setOpen}} as |d|>
      <Button @variant="outline" {{d.trigger}}>Open clarification</Button>
      <d.Content>
        <Questionnaire @defaultItem="scope" @items={{items}} @onSubmit={{this.handleSubmit}} as |q|>
          <q.Item @name="scope" @required={{true}} as |i|>
            <d.Header>
              <q.Progress />
              {{#if i.isActive}}
                <d.Title {{i.title}}>
                  Which files are in scope?
                </d.Title>
                <d.Description {{i.description}}>
                  Choose how broadly the agent can update the workspace.
                </d.Description>
              {{/if}}
            </d.Header>
            <i.Choices>
              <i.Choice @value="component">
                Component only
              </i.Choice>
              <i.Choice @value="feature">
                Complete feature directory
              </i.Choice>
              <i.Choice @value="workspace">
                Any related workspace file
              </i.Choice>
            </i.Choices>
            <i.Error />
          </q.Item>

          <q.Item @name="tests" @required={{true}} as |i|>
            <d.Header>
              <q.Progress />
              {{#if i.isActive}}
                <d.Title {{i.title}}>
                  How much verification is needed?
                </d.Title>
                <d.Description {{i.description}}>
                  Choose the checks the agent should run before handoff.
                </d.Description>
              {{/if}}
            </d.Header>
            <i.Choices>
              <i.Choice @value="targeted">
                Targeted tests
              </i.Choice>
              <i.Choice @value="package">
                Package tests
              </i.Choice>
              <i.Choice @value="full">
                Full workspace verification
              </i.Choice>
            </i.Choices>
            <i.Error />
          </q.Item>

          <d.Footer>
            <Button type="button" @variant="outline" {{d.close}}>
              Cancel
            </Button>
            <q.Actions>
              <q.Previous />
              <q.Next>Next</q.Next>
              <q.Submit>Send answer</q.Submit>
            </q.Actions>
          </d.Footer>
        </Questionnaire>
      </d.Content>
    </Dialog>
  </template>
}
