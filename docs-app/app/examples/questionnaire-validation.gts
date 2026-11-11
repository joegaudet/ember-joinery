import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Card, Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  { name: 'detail', required: true },
  { name: 'audience', required: true },
]

type ItemName = 'detail' | 'audience'
type Errors = Partial<Record<ItemName, string>>

interface Issue {
  path: ItemName
  message: string
}

/**
 * Upstream checks the answers with a zod schema (two enums, then a refinement); the guide has
 * no zod, so this is that schema written out: the same rules, in the same order, with zod's
 * message for a missing answer.
 */
function validate(answers: Record<string, unknown>): Issue[] {
  const issues: Issue[] = []
  const missing = 'Required'
  if (answers['detail'] !== 'summary' && answers['detail'] !== 'complete') {
    issues.push({ path: 'detail', message: missing })
  }
  if (answers['audience'] !== 'team' && answers['audience'] !== 'public') {
    issues.push({ path: 'audience', message: missing })
  }
  if (!issues.length && answers['audience'] === 'public' && answers['detail'] === 'summary') {
    issues.push({
      path: 'detail',
      message: 'Public answers need enough context. Choose a complete answer.',
    })
  }
  return issues
}

export default class QuestionnaireValidation extends Component {
  @tracked item = 'detail'
  @tracked errors: Errors = {}

  setItem = (item: string) => (this.item = item)

  clearError = (name: ItemName) => {
    if (!this.errors[name]) return
    const nextErrors = { ...this.errors }
    delete nextErrors[name]
    this.errors = nextErrors
  }

  clearDetail = () => this.clearError('detail')

  clearAudience = () => this.clearError('audience')

  handleSubmit = (event: SubmitEvent) => {
    event.preventDefault()

    const answers = Object.fromEntries(new FormData(event.currentTarget as HTMLFormElement))
    const issues = validate(answers)

    if (!issues.length) {
      this.errors = {}
      toast('Agent response configured', {
        description: `Detail: ${String(answers['detail'])} · Audience: ${String(answers['audience'])}`,
      })
      return
    }

    const nextErrors: Errors = {}
    for (const issue of issues) nextErrors[issue.path] ??= issue.message

    this.errors = nextErrors
    this.item = issues[0]!.path
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
      <Card class="w-full" as |c|>
        <q.Item
          @invalid={{if this.errors.detail true false}}
          @name="detail"
          @required={{true}}
          as |i|
        >
          <c.Header>
            <i.Title>
              How much detail should the answer include?
            </i.Title>
            <i.Description>
              Choose the response depth.
            </i.Description>
            <c.Action>
              <q.Progress class="min-w-0" as |p|>
                {{p.current}}
                /
                {{p.total}}
              </q.Progress>
            </c.Action>
          </c.Header>
          <c.Content>
            <i.Choices>
              <i.Choice @value="summary" @onCheckedChange={{this.clearDetail}}>
                Concise summary
              </i.Choice>
              <i.Choice @value="complete" @onCheckedChange={{this.clearDetail}}>
                Complete answer
              </i.Choice>
            </i.Choices>
            <i.Error @message={{this.errors.detail}} />
          </c.Content>
        </q.Item>

        <q.Item
          @invalid={{if this.errors.audience true false}}
          @name="audience"
          @required={{true}}
          as |i|
        >
          <c.Header>
            <i.Title>Who will read the answer?</i.Title>
            <i.Description>
              Public answers require complete context.
            </i.Description>
            <c.Action>
              <q.Progress class="min-w-0" as |p|>
                {{p.current}}
                /
                {{p.total}}
              </q.Progress>
            </c.Action>
          </c.Header>
          <c.Content>
            <i.Choices>
              <i.Choice @value="team" @onCheckedChange={{this.clearAudience}}>
                My team
              </i.Choice>
              <i.Choice @value="public" @onCheckedChange={{this.clearAudience}}>
                Public audience
              </i.Choice>
            </i.Choices>
            <i.Error @message={{this.errors.audience}} />
          </c.Content>
        </q.Item>

        <c.Footer>
          <q.Actions>
            <q.Previous />
            <q.Next>Next</q.Next>
            <q.Submit>Validate answers</q.Submit>
          </q.Actions>
        </c.Footer>
      </Card>
    </Questionnaire>
  </template>
}
