import { Card, Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  {
    choices: [{ value: 'fix' }, { value: 'refactor' }, { value: 'docs' }],
    name: 'task',
    required: true,
  },
  {
    choices: [{ value: 'summary' }, { value: 'files' }, { value: 'review' }],
    name: 'output',
    required: true,
  },
]

function handleSubmit(event: SubmitEvent) {
  event.preventDefault()

  const formData = new FormData(event.currentTarget as HTMLFormElement)

  toast('Agent task created', {
    description: `Task: ${String(formData.get('task') ?? 'None')} · Handoff: ${String(formData.get('output') ?? 'None')}`,
  })
}

<template>
  {{!-- Upstream renders each title as a CardTitle (render={<CardTitle />}); here the card's
      title takes the questionnaire title's part with {{i.title}}, and the item names itself
      by its id, as upstream's aria-labelledby does. --}}
  <Questionnaire
    class="mx-auto max-w-md"
    @defaultItem="task"
    @items={{items}}
    @shortcuts="numbers"
    @onSubmit={{handleSubmit}}
    as |q|
  >
    <Card as |c|>
      <q.Item aria-labelledby="questionnaire-card-task" @name="task" @required={{true}} as |i|>
        <c.Header>
          <c.Title id="questionnaire-card-task" {{i.title}}>
            What should the agent work on?
          </c.Title>
          <c.Description {{i.description}}>
            Choose the task that should be handled next.
          </c.Description>
          <c.Action>
            <q.Progress />
          </c.Action>
        </c.Header>
        <c.Content>
          <i.Choices>
            <i.Choice @value="fix">
              Fix the failing tests
            </i.Choice>
            <i.Choice @value="refactor">
              Refactor the data layer
            </i.Choice>
            <i.Choice @value="docs">
              Update the integration guide
            </i.Choice>
          </i.Choices>
          <i.Error />
        </c.Content>
      </q.Item>

      <q.Item aria-labelledby="questionnaire-card-output" @name="output" @required={{true}} as |i|>
        <c.Header>
          <c.Title id="questionnaire-card-output" {{i.title}}>
            What should the final handoff include?
          </c.Title>
          <c.Description {{i.description}}>
            Pick the level of detail needed for review.
          </c.Description>
          <c.Action>
            <q.Progress />
          </c.Action>
        </c.Header>
        <c.Content>
          <i.Choices>
            <i.Choice @value="summary">
              Summary only
            </i.Choice>
            <i.Choice @value="files">
              Summary and changed files
            </i.Choice>
            <i.Choice @value="review">
              Full review handoff
            </i.Choice>
          </i.Choices>
          <i.Error />
        </c.Content>
      </q.Item>

      <c.Footer>
        <q.Actions class="w-full">
          <q.Previous />
          <q.Next>Next</q.Next>
          <q.Submit>Create task</q.Submit>
        </q.Actions>
      </c.Footer>
    </Card>
  </Questionnaire>
</template>
