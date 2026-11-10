import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import {
  NativeSelect,
  Questionnaire,
  toast,
  type QuestionnaireShortcutMode,
} from '@ember-joinery/ember'

const items = [
  {
    choices: [{ value: 'inspect' }, { value: 'tests' }, { value: 'patch' }],
    name: 'action',
    required: true,
  },
]

export default class QuestionnaireShortcuts extends Component {
  @tracked shortcuts: QuestionnaireShortcutMode | undefined = 'letters'

  setShortcuts = (value: string) => {
    this.shortcuts = value === 'letters' || value === 'numbers' ? value : undefined
  }

  handleSubmit = (event: SubmitEvent) => {
    event.preventDefault()

    const action = new FormData(event.currentTarget as HTMLFormElement).get('action')

    toast('Next action selected', {
      description: `Action: ${String(action ?? 'None')} · Shortcuts: ${this.shortcuts ?? 'none'}`,
    })
  }

  <template>
    <div class="relative mx-auto flex h-full w-full max-w-md flex-col">
      <NativeSelect
        aria-label="Shortcut style"
        class="absolute end-0 top-0"
        @value={{if this.shortcuts this.shortcuts "none"}}
        @onValueChange={{this.setShortcuts}}
        as |s|
      >
        <s.Option @value="none">No shortcuts</s.Option>
        <s.Option @value="letters">Letters</s.Option>
        <s.Option @value="numbers">Numbers</s.Option>
      </NativeSelect>

      <Questionnaire
        class="mt-auto"
        @items={{items}}
        @shortcuts={{this.shortcuts}}
        @onSubmit={{this.handleSubmit}}
        as |q|
      >
        <q.Item @name="action" @required={{true}} as |i|>
          <i.Title>
            What should the agent do next?
          </i.Title>
          <i.Description>
            Use the displayed shortcut or navigate with the keyboard.
          </i.Description>
          <i.Choices>
            <i.Choice @value="inspect">
              Inspect the implementation
            </i.Choice>
            <i.Choice @value="tests">
              Run the relevant tests
            </i.Choice>
            <i.Choice @value="patch">
              Prepare the patch
            </i.Choice>
          </i.Choices>
          <i.Error />
        </q.Item>

        <q.Actions>
          <q.Submit>Confirm action</q.Submit>
        </q.Actions>
      </Questionnaire>
    </div>
  </template>
}
