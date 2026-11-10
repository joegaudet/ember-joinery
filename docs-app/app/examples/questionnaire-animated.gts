import { Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  { name: 'task', required: true },
  { name: 'review', required: true },
  { name: 'delivery', required: true },
]

function handleSubmit(event: SubmitEvent) {
  event.preventDefault()

  const formData = new FormData(event.currentTarget as HTMLFormElement)

  toast('Agent workflow saved', {
    description: `Task: ${String(formData.get('task') ?? 'None')} · Review: ${String(formData.get('review') ?? 'None')} · Delivery: ${String(formData.get('delivery') ?? 'None')}`,
  })
}

<template>
  <Questionnaire
    class="mx-auto max-w-md"
    @defaultItem="task"
    @items={{items}}
    @onSubmit={{handleSubmit}}
    as |q|
  >
    <q.Progress />

    <q.Item
      class="data-active:animate-in data-active:fade-in-0 data-active:slide-in-from-bottom-2 data-active:duration-300 motion-reduce:animate-none"
      @name="task"
      @required={{true}}
      as |i|
    >
      <i.Title>What should the agent do?</i.Title>
      <i.Description>
        Choose the task for this run.
      </i.Description>
      <i.Choices>
        <i.Choice @value="implement">
          Implement the requested change
        </i.Choice>
        <i.Choice @value="debug">
          Debug the current behavior
        </i.Choice>
        <i.Choice @value="review">
          Review the implementation
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item
      class="data-active:animate-in data-active:fade-in-0 data-active:slide-in-from-bottom-2 data-active:duration-300 motion-reduce:animate-none"
      @name="review"
      @required={{true}}
      as |i|
    >
      <i.Title>
        How should the work be reviewed?
      </i.Title>
      <i.Description>
        Select the verification depth.
      </i.Description>
      <i.Choices>
        <i.Choice @value="targeted">
          Targeted checks
        </i.Choice>
        <i.Choice @value="complete">
          Complete test suite
        </i.Choice>
        <i.Choice @value="manual">
          Tests and manual QA
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item
      class="data-active:animate-in data-active:fade-in-0 data-active:slide-in-from-bottom-2 data-active:duration-300 motion-reduce:animate-none"
      @name="delivery"
      @required={{true}}
      as |i|
    >
      <i.Title>
        How should the result be delivered?
      </i.Title>
      <i.Description>
        Choose the final handoff format.
      </i.Description>
      <i.Choices>
        <i.Choice @value="summary">
          Concise summary
        </i.Choice>
        <i.Choice @value="diff">
          Summary and changed files
        </i.Choice>
        <i.Choice @value="handoff">
          Detailed review handoff
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
</template>
