import { Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  {
    choices: [{ value: 'source' }, { value: 'tests' }, { value: 'docs' }, { value: 'history' }],
    name: 'context',
    required: true,
  },
]

function handleSubmit(event: SubmitEvent) {
  event.preventDefault()

  const context = new FormData(event.currentTarget as HTMLFormElement).getAll('context')

  toast('Context selected', {
    description: `Context: ${context.join(', ') || 'None'}`,
  })
}

<template>
  <Questionnaire
    class="mx-auto max-w-md"
    @items={{items}}
    @shortcuts="letters"
    @onSubmit={{handleSubmit}}
    as |q|
  >
    <q.Item @name="context" @multiple={{true}} @required={{true}} as |i|>
      <i.Title>
        What context should the agent inspect?
      </i.Title>
      <i.Description>
        Select every source that may affect the implementation.
      </i.Description>
      <i.Choices>
        <i.Choice @value="source">
          Relevant source files
        </i.Choice>
        <i.Choice @value="tests">
          Existing tests
        </i.Choice>
        <i.Choice @value="docs">
          Architecture documentation
        </i.Choice>
        <i.Choice @value="history">
          Recent commit history
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Actions>
      <q.Submit>Share context</q.Submit>
    </q.Actions>
  </Questionnaire>
</template>
