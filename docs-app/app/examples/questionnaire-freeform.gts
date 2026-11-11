import { Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  {
    choices: [{ value: 'incremental' }, { value: 'module' }, { value: 'rewrite' }],
    name: 'approach',
    required: true,
  },
]

function handleSubmit(event: SubmitEvent) {
  event.preventDefault()

  const approach = new FormData(event.currentTarget as HTMLFormElement).get('approach')

  toast('Approach selected', {
    description: `Approach: ${String(approach ?? 'None')}`,
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
    <q.Item @name="approach" @required={{true}} as |i|>
      <i.Title>
        How should the agent approach this refactor?
      </i.Title>
      <i.Description>
        Choose a strategy or write a more specific instruction.
      </i.Description>
      <i.Choices>
        <i.Choice @value="incremental">
          Make the smallest safe change
        </i.Choice>
        <i.Choice @value="module">
          Refactor one module at a time
        </i.Choice>
        <i.Choice @value="rewrite">
          Replace the implementation completely
        </i.Choice>
        <i.Input
          aria-label="Another refactoring approach"
          placeholder="Describe another approach…"
        />
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Actions>
      <q.Submit>Use this approach</q.Submit>
    </q.Actions>
  </Questionnaire>
</template>
